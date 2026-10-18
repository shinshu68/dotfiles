#!/usr/bin/env bash
# カレントディレクトリ(作成したプロジェクト)を pj-status の対象一覧に追加する。
# 一覧は WSL 側の ~/.claude/skills/pj-status/projects.txt で一元管理しているので、
# Windows 側(Git Bash など)から実行された場合も、WSL の中でそのファイルを編集する。
#
# 出力の最終行:
#   ADDED: <書き込んだ行>      追加した
#   ALREADY: <既存の行>        既に登録済みなので何もしていない
#   ERROR: <理由>              追加できなかった
#
# 環境変数(主にテスト用):
#   PJ_STATUS_PROJECTS  projects.txt のパス(既定: ~/.claude/skills/pj-status/projects.txt)

set -u

# ---- Windows 側から呼ばれた場合は、WSL に処理を渡す ----
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    if ! command -v wsl.exe >/dev/null 2>&1; then
      echo "ERROR: wsl.exe が見つかりません"
      exit 1
    fi
    export MSYS_NO_PATHCONV=1
    # Windows 形式のパス(C:/... や //wsl.localhost/...)を WSL 側で変換させる
    exec wsl.exe -e bash -s -- --from-windows "$(pwd -W)" < "${BASH_SOURCE[0]}"
    ;;
esac

# ---- 対象のパスを決める(WSL 形式) ----
if [[ "${1:-}" == "--from-windows" ]]; then
  winpath="${2//\//\\}"
  target="$(wslpath -u "$winpath" 2>/dev/null)" || {
    echo "ERROR: WSL のパスに変換できません: $2"
    exit 1
  }
else
  target="$(pwd)"
fi
target="${target%/}"

projects="${PJ_STATUS_PROJECTS:-$HOME/.claude/skills/pj-status/projects.txt}"
skill_dir="$(dirname "$projects")"

if [[ ! -d "$skill_dir" ]]; then
  echo "ERROR: pj-status スキルが見つかりません: $skill_dir"
  exit 1
fi

# projects.txt がまだ無ければ、ひな形から作る(ひな形も無ければ空で作る)
if [[ ! -f "$projects" ]]; then
  if [[ -f "$skill_dir/projects.example.txt" ]]; then
    cp "$skill_dir/projects.example.txt" "$projects"
  else
    : > "$projects"
  fi
  echo "INFO: projects.txt が無かったので作成しました"
fi

# 書き込む行: ホームの下なら ~ で書く(既存の行の書き方にそろえる)
if [[ "$target" == "$HOME" || "$target" == "$HOME/"* ]]; then
  entry="~${target#"$HOME"}"
else
  entry="$target"
fi

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

# 既に登録済みか確認する(コメント・「| バックログ名」・~ の表記ゆれを吸収して比べる)
target_real="$(realpath -m "$target")"
while IFS= read -r raw || [[ -n "$raw" ]]; do
  line="$(trim "${raw%%#*}")"
  [[ -z "$line" ]] && continue
  p="$(trim "${line%%|*}")"
  case "$p" in
    "~") p="$HOME" ;;
    "~/"*) p="$HOME/${p#\~/}" ;;
  esac
  if [[ "$(realpath -m "$p")" == "$target_real" ]]; then
    echo "ALREADY: $line"
    exit 0
  fi
done < "$projects"

# 末尾に改行が無いファイルに追記すると前の行とつながるので、必要なら改行を足す
if [[ -s "$projects" && -n "$(tail -c1 "$projects")" ]]; then
  echo >> "$projects"
fi
echo "$entry" >> "$projects"
echo "ADDED: $entry"
