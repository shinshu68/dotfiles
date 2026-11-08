#!/usr/bin/env bash
# UserPromptSubmit フック: /kickoff で始まるプロンプトのとき、引き継ぎメモのタイトルをセッションのタイトルにする
# スキルからはタイトルを変えられないため、フックの sessionTitle 出力で設定する

# jq のない環境 (jq を入れる前の Windows など) では何もしない
command -v jq >/dev/null || exit 0

input=$(cat)
# VSCode 拡張では、開いているファイルなどの <ide_…> ブロックがプロンプトの先頭に付いてくる
prompt=$(jq -r '.prompt // "" | sub("^(\\s*<(ide_[a-z_]+)>[\\s\\S]*?</\\2>)*\\s*"; "")' <<<"$input")
[[ $prompt == /kickoff* ]] || exit 0

# /rename などで付けたタイトルは上書きしない
[[ -z $(jq -r '.session_title // ""' <<<"$input") ]] || exit 0

# 自動メモリは transcript と同じプロジェクトのディレクトリの下にある
transcript_path=$(jq -r '.transcript_path // ""' <<<"$input")
cwd=$(jq -r '.cwd // ""' <<<"$input")
repo_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || echo "$cwd")

for memo in "$(dirname "$transcript_path")/memory/handoff.md" "$HOME/.claude/handoff/$(basename "$repo_root").md"; do
  [[ -f $memo ]] || continue
  title=$(sed -n '/^# 引き継ぎ: */{s///p;q}' "$memo")
  [[ -n $title ]] || exit 0
  jq -n --arg title "$title" '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", sessionTitle: $title}}'
  exit 0
done
