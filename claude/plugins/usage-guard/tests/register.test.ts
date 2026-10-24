import { expect, test } from 'claude-code/testing'
import type { TestBody } from 'claude-code/testing'

// 使用率を差し替えられるようにする (テストの中で書き換える)
let limits: { kind: string; percentUsed: number; resetsAt?: string }[] = []

const setup = (on: Parameters<TestBody>[1]) => {
  on('session.usage', () => ({
    value: { startedAt: 0, context: {}, rateLimits: limits },
  }) as never)
  on('tool.call', () => ({ result: {} }))
  on('ui.toast', () => ({ value: undefined }))
}

test('閾値未満では伝えない', async ($, on) => {
  setup(on)
  limits = [{ kind: 'five_hour', percentUsed: 89.9, resetsAt: '2026-10-25T09:00:00Z' }]
  const r = await $.tool.call({ tool: 'Bash', command: 'ls' })
  expect(r.context).toBeUndefined()
})

test('閾値以上で1回だけ伝え、新しいウィンドウでは再び伝える', async ($, on) => {
  setup(on)
  limits = [
    { kind: 'five_hour', percentUsed: 91.5, resetsAt: '2026-10-25T09:00:00Z' },
    { kind: 'seven_day', percentUsed: 40, resetsAt: '2026-10-30T00:00:00Z' },
  ]
  const first = await $.tool.call({ tool: 'Bash', command: 'ls' })
  expect(first.context?.[0]).toMatch(/5時間枠が上限の 91.5% に達しています/)

  const second = await $.tool.call({ tool: 'Bash', command: 'ls' })
  expect(second.context).toBeUndefined()

  limits = [{ kind: 'five_hour', percentUsed: 95, resetsAt: '2026-10-25T14:00:00Z' }]
  const third = await $.tool.call({ tool: 'Bash', command: 'ls' })
  expect(third.context?.[0]).toMatch(/95%/)
})

test('サブエージェントの呼び出しでは伝えない', async ($, on) => {
  setup(on)
  limits = [{ kind: 'seven_day', percentUsed: 99, resetsAt: '2026-10-30T00:00:00Z' }]
  const r = await $.tool.call({ tool: 'Bash', command: 'ls', agentId: 'a1' })
  expect(r.context).toBeUndefined()
})

test('閾値は userConfig で変えられる', { options: { threshold: 50 } }, async ($, on) => {
  setup(on)
  limits = [{ kind: 'seven_day', percentUsed: 55, resetsAt: '2026-10-31T00:00:00Z' }]
  const r = await $.tool.call({ tool: 'Bash', command: 'ls' })
  expect(r.context?.[0]).toMatch(/7日枠/)
})

test('使用率をステータス欄に出さない', async ($, on) => {
  setup(on)
  let statusCalls = 0
  on('ui.status', () => {
    statusCalls++
    return { value: undefined }
  })
  limits = [
    { kind: 'five_hour', percentUsed: 21, resetsAt: '2026-10-25T09:00:00Z' },
    { kind: 'seven_day', percentUsed: 95, resetsAt: '2026-10-30T00:00:00Z' },
  ]
  // 計測のイベント (engine の代わりに changed を返す) と、閾値を超えたときのツール呼び出しの両方で確かめる
  on('session.measure', (_, e) => ({ changed: e.changed }))
  await $.session.measure({
    context: {},
    rateLimits: limits,
    changed: ['rateLimits'],
  } as never)
  await $.tool.call({ tool: 'Bash', command: 'ls' })
  expect(statusCalls).toBe(0)
})
