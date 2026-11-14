#!/usr/bin/env bash
# agents/common.md と codex/codex.md をつなげて、~/.codex/AGENTS.md のリンク先を作る
set -euo pipefail

codex_dir=$(cd "$(dirname "$0")" && pwd)
root=$(dirname "$codex_dir")
out="$codex_dir/AGENTS.generated.md"
# Codex の project_doc_max_bytes の既定値
limit=32768

tmp=$(mktemp "$out.XXXXXX")
trap 'rm -f "$tmp"' EXIT
{
    printf '<!-- 自動生成のため直接編集しない。元は dotfiles の agents/common.md と codex/codex.md -->\n\n'
    printf '# 個人設定\n\n'
    cat "$root/agents/common.md"
    printf '\n'
    cat "$codex_dir/codex.md"
} > "$tmp"

size=$(wc -c < "$tmp")
if [ "$size" -gt "$limit" ]; then
    echo "warning: $out is $size bytes (Codex reads only the first $limit bytes)" >&2
fi

if cmp -s "$tmp" "$out"; then
    exit 0
fi
chmod 644 "$tmp"
mv "$tmp" "$out"
echo "changed: $out"
