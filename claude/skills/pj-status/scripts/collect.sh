#!/usr/bin/env bash
# projects.txt(projects.example.txt をコピーして作る PC ごとの設定)に列挙したプロジェクトを順に回り、
# git の状態とバックログ(~/.claude/backlog-data/<プロジェクト名>.md)の残タスクを
# Markdown にまとめて標準出力に出す。読み取りのみで、ファイルやリポジトリは一切変更しない。
#
# 使い方:
#   collect.sh            全プロジェクトを表示(未着手は各プロジェクト上位5件まで)
#   collect.sh --all      未着手を省略せずに全件表示
#   collect.sh <名前>     名前(またはパス)に <名前> を含むプロジェクトだけ表示
#
# 環境変数(主にテスト用):
#   PJ_STATUS_CONFIG   設定ファイルのパス(既定: スキル直下の projects.txt)
#   BACKLOG_DATA_DIR   バックログの置き場所(既定: ~/.claude/backlog-data)
#   PJ_STATUS_WSL_SCRIPT  Windows から呼ばれたときに実行する WSL 内のスクリプトのパス
#                         (既定: WSL の ~/.claude/skills/pj-status/scripts/collect.sh)

set -u

# Windows 側(Git Bash など)から実行された場合は、WSL 内の同じスクリプトに処理を渡す。
# プロジェクトとバックログは WSL 側にあり、Windows の git から \\wsl.localhost のリポジトリを
# 読むと遅いうえに「所有者が異なる」として拒否されることがあるため、集計は常に WSL の中で行う。
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    if command -v wsl.exe >/dev/null 2>&1; then
      # Git Bash が / で始まる引数を Windows のパスに書き換えないようにする
      export MSYS_NO_PATHCONV=1
      # 置き場所を変えている場合は、Windows 側で指定した値を WSL に引き継ぐ
      [[ -n "${PJ_STATUS_WSL_SCRIPT:-}" ]] && export WSLENV="${WSLENV:+$WSLENV:}PJ_STATUS_WSL_SCRIPT"
      exec wsl.exe -e bash -c '
        s="${PJ_STATUS_WSL_SCRIPT:-$HOME/.claude/skills/pj-status/scripts/collect.sh}"
        if [[ ! -f "$s" ]]; then
          echo "WSL 内にスクリプトが見つかりません: $s"
          echo "WSL 側にスキルを置くか、PJ_STATUS_WSL_SCRIPT で場所を指定してください。"
          exit 1
        fi
        exec bash "$s" "$@"' pj-status "$@"
    fi
    echo "wsl.exe が見つかりません。pj-status は WSL の中で実行してください。"
    exit 1
    ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config="${PJ_STATUS_CONFIG:-$script_dir/../projects.txt}"
backlog_dir="${BACKLOG_DATA_DIR:-$HOME/.claude/backlog-data}"

max_todo=5
filter=""
for arg in "$@"; do
  case "$arg" in
    --all) max_todo=0 ;;
    *) filter="$arg" ;;
  esac
done

if [[ ! -f "$config" ]]; then
  echo "設定ファイルが見つかりません: $config"
  echo "同じ場所の projects.example.txt を projects.txt としてコピーし、対象プロジェクトのパスを1行に1つずつ書いてください。"
  echo "(projects.txt は PC ごとの設定なので git 管理していません)"
  exit 1
fi

# 先頭の ~ をホームディレクトリに展開する
expand_path() {
  local p="$1"
  case "$p" in
    "~") p="$HOME" ;;
    "~/"*) p="$HOME/${p#\~/}" ;;
  esac
  printf '%s' "$p"
}

# 前後の空白を取り除く
trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

# backlog スキルと同じ考え方でプロジェクト名の候補を出す
# (リモート origin のリポジトリ名 → git のトップディレクトリ名 → 指定パスのディレクトリ名)
name_candidates() {
  local p="$1" url top
  url=$(git -C "$p" remote get-url origin 2>/dev/null) && {
    url="${url%.git}"; url="${url##*/}"; url="${url##*:}"
    [[ -n "$url" ]] && echo "$url"
  }
  top=$(git -C "$p" rev-parse --show-toplevel 2>/dev/null) && basename "$top"
  basename "$p"
}

# UNIX 時刻から「3日前」のような相対表記を作る
relative_time() {
  local ts="$1" now diff
  now=$(date +%s)
  diff=$(( now - ts ))
  if   (( diff < 60 ));      then echo "1分以内"
  elif (( diff < 3600 ));    then echo "$(( diff / 60 ))分前"
  elif (( diff < 86400 ));   then echo "$(( diff / 3600 ))時間前"
  elif (( diff < 2592000 )); then echo "$(( diff / 86400 ))日前"
  else echo "$(date -d "@$ts" +%Y-%m-%d 2>/dev/null || echo "$(( diff / 86400 ))日前")"
  fi
}

# バックログを読み、1行目に「進行中件数<TAB>未着手件数<TAB>完了件数」、
# 2行目以降に詳細の Markdown を出す
parse_backlog() {
  awk -v max_todo="$1" '
    # タスク行を「#004 [高] タイトル」の形に整える
    function fmt(line) {
      sub(/^- \[.\] /, "", line)
      gsub(/\*\*/, "", line)
      if (sub(/`優先度:/, "[", line)) sub(/`/, "]", line)
      return line
    }
    /^## / { sec = substr($0, 4); last = ""; next }
    /^- \[/ {
      if (sec == "進行中")      { np++; prog[np] = fmt($0); last = "prog" }
      else if (sec == "未着手") { nt++; todo[nt] = fmt($0); last = "todo" }
      else if (sec == "完了")   { nd++; last = "" }
      next
    }
    # 進行中タスクの詳細メモ(> 行)は進み具合が書かれるので、タスクの後ろに添える
    /^[ \t]*>/ {
      if (last == "prog") {
        note = $0; sub(/^[ \t]*>[ \t]*/, "", note)
        if (note != "") prog[np] = prog[np] (index(prog[np], " — ") ? " / " : " — ") note
      }
      next
    }
    END {
      printf "%d\t%d\t%d\n", np, nt, nd
      print "**進行中 (" np+0 ")**"
      if (np == 0) print "- なし"
      for (i = 1; i <= np; i++) print "- " prog[i]
      print ""
      print "**未着手 (" nt+0 ")**"
      if (nt == 0) print "- なし"
      limit = (max_todo > 0 && nt > max_todo) ? max_todo : nt
      for (i = 1; i <= limit; i++) print "- " todo[i]
      if (limit < nt) print "- ほか " nt - limit "件"
    }
  ' "$2"
}

summary=""
details=""
count=0

while IFS= read -r raw || [[ -n "$raw" ]]; do
  line="$(trim "${raw%%#*}")"
  [[ -z "$line" ]] && continue

  # 「パス | バックログ名」の形式なら、バックログ名を明示指定として扱う
  override=""
  if [[ "$line" == *"|"* ]]; then
    override="$(trim "${line#*|}")"
    line="$(trim "${line%%|*}")"
  fi
  path="$(expand_path "$line")"

  # 表示名はディレクトリ名。絞り込みはパスとバックログ名にも当てる
  display="$(basename "$path")"
  if [[ -n "$filter" && "$path" != *"$filter"* && "$override" != *"$filter"* ]]; then
    continue
  fi
  count=$(( count + 1 ))

  if [[ ! -d "$path" ]]; then
    summary+="| $display | - | - | - | - | - | パスが見つかりません |"$'\n'
    details+="### $display"$'\n'"\`$line\` が見つかりません。projects.txt のパスを確認してください。"$'\n\n'
    continue
  fi

  # ---- git の状態 ----
  if git -C "$path" rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git -C "$path" symbolic-ref --short -q HEAD 2>/dev/null) \
      || branch="(detached $(git -C "$path" rev-parse --short HEAD 2>/dev/null))"
    dirty=$(git -C "$path" --no-optional-locks status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    ahead=$(git -C "$path" rev-list --count '@{u}..HEAD' 2>/dev/null) || ahead=""
    if ts=$(git -C "$path" log -1 --format=%ct 2>/dev/null) && [[ -n "$ts" ]]; then
      subject=$(git -C "$path" log -1 --format=%s)
      last="$(relative_time "$ts")"
      last_detail="$last「$subject」"
    else
      last="コミットなし"; last_detail="コミットなし"
    fi
    git_line="ブランチ \`$branch\` ・未コミット ${dirty}件"
    [[ -n "$ahead" && "$ahead" != "0" ]] && git_line+=" ・未push ${ahead}件"
    git_line+=" ・最終コミット $last_detail"
    dirty_cell="$dirty"
  else
    branch=""; dirty_cell="-"; last="-"
    git_line="git 管理外"
  fi

  # ---- バックログ ----
  backlog_file=""
  if [[ -n "$override" ]]; then
    [[ -f "$backlog_dir/$override.md" ]] && backlog_file="$backlog_dir/$override.md"
  else
    while IFS= read -r cand; do
      if [[ -f "$backlog_dir/$cand.md" ]]; then backlog_file="$backlog_dir/$cand.md"; break; fi
    done < <(name_candidates "$path" | awk '!seen[$0]++')
  fi

  details+="### $display"$'\n'"$git_line"$'\n\n'
  if [[ -n "$backlog_file" ]]; then
    parsed="$(parse_backlog "$max_todo" "$backlog_file")"
    IFS=$'\t' read -r np nt nd <<< "$(head -n1 <<< "$parsed")"
    details+="$(tail -n +2 <<< "$parsed")"$'\n\n'"完了: ${nd}件"$'\n\n'
  else
    np="-"; nt="-"; nd="-"
    details+="バックログがありません(\`$backlog_dir\` に該当するファイルなし)"$'\n\n'
  fi

  branch_cell="-"; [[ -n "$branch" ]] && branch_cell="\`$branch\`"
  summary+="| $display | $branch_cell | $dirty_cell | $np | $nt | $nd | $last |"$'\n'
done < "$config"

if (( count == 0 )); then
  if [[ -n "$filter" ]]; then
    echo "「$filter」に一致するプロジェクトが projects.txt にありません。"
  else
    echo "projects.txt に対象プロジェクトが登録されていません。"
  fi
  exit 0
fi

echo "## プロジェクト進捗"
echo
echo "| プロジェクト | ブランチ | 未コミット | 進行中 | 未着手 | 完了 | 最終コミット |"
echo "|---|---|---|---|---|---|---|"
printf '%s' "$summary"
echo
printf '%s' "$details"
