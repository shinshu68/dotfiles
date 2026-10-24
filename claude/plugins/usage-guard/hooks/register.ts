import type { Register, SessionRateLimit } from 'claude-code'

/** 対象にするウィンドウと、その表示名 */
const WINDOW_LABELS: Readonly<Record<string, string>> = {
  five_hour: '5時間枠',
  seven_day: '7日枠',
}

/** ステータス欄で使う短い表示名 */
const SHORT_LABELS: Readonly<Record<string, string>> = {
  five_hour: '5h',
  seven_day: '7d',
}

/** ISO 8601 のリセット時刻を「2026-10-25 18:00」の形にする (ローカル時刻) */
const formatResetsAt = (iso: string | undefined): string | undefined => {
  if (iso === undefined) return undefined
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return iso
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`
}

/** 通知の文面。命令ではなく事実を述べる形にする */
const describe = (limit: SessionRateLimit): string => {
  const label = WINDOW_LABELS[limit.kind] ?? limit.kind
  const resets = formatResetsAt(limit.resetsAt)
  const tail = resets === undefined ? '' : ` (リセット: ${resets})`
  return `課金プランの使用量制限の${label}が上限の ${limit.percentUsed}% に達しています${tail}。`
}

/** ウィンドウを区別するキー。resetsAt が変われば別のウィンドウとして扱う */
const windowKey = (limit: SessionRateLimit): string => `${limit.kind}@${limit.resetsAt ?? ''}`

export const register: Register = (on, options) => {
  const threshold = typeof options.threshold === 'number' ? options.threshold : 90

  // このセッションで伝え済みのウィンドウ。リロードで初期化されるが許容する
  const notified = new Set<string>()

  on('tool.call', async ($, e, next) => {
    const ran = await next(e)

    // 拒否されたツールと、サブエージェントの呼び出しでは伝えない
    if (ran.deny !== undefined || e.agentId !== undefined) return ran

    const { rateLimits } = await $.session.usage()
    const reached = rateLimits.filter(
      l => l.kind in WINDOW_LABELS && l.percentUsed >= threshold && !notified.has(windowKey(l)),
    )
    if (reached.length === 0) return ran

    for (const l of reached) notified.add(windowKey(l))
    const message = reached.map(describe).join('\n')
    $.ui.toast(message, { timeoutMs: 10000 })

    return { ...ran, context: [...(ran.context ?? []), message] }
  }).catch(($, e, next) => next(e)) // 失敗してもツールの実行は妨げない (呼び済みなら結果を再生する)

  // ステータス欄に常に使用率を出す
  on('session.measure', ($, e, next) => {
    const parts = e.rateLimits
      .filter(l => l.kind in SHORT_LABELS)
      .map(l => `${SHORT_LABELS[l.kind]} ${l.percentUsed}%`)
    $.ui.status(parts.length === 0 ? undefined : parts.join(' / '))
    return next(e)
  })
}
