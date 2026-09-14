#!/usr/bin/env bash
#
# create_branch.sh
#
# 想定フロー:
#   develop ブランチ上にいる状態から、指定した名前の新しいブランチを
#   「現在の位置(未コミットの変更を含む)」から作成して切り替える。
#   develop には何もコミットしていない前提のため、develop 自体は一切変更しない
#   (git checkout -b は新しいブランチを作るだけで、develop の履歴には触れない)。
#
# 使い方:
#   bash scripts/create_branch.sh <new-branch-name>
#
set -euo pipefail

new_branch="${1:-}"

if [ -z "$new_branch" ]; then
  echo "ERROR: 新しいブランチ名を引数で指定してください。" >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "ERROR: ここはgitリポジトリではありません。" >&2
  exit 1
fi

current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")

if [ "$current_branch" != "develop" ]; then
  echo "ERROR: 現在developブランチにいません(現在: ${current_branch:-detached HEAD})。安全のため中断します。" >&2
  exit 1
fi

if git show-ref --verify --quiet "refs/heads/${new_branch}"; then
  echo "ERROR: ブランチ '${new_branch}' は既に存在します。別の名前を指定してください。" >&2
  exit 1
fi

git checkout -b "$new_branch"

echo "CREATED_BRANCH:${new_branch}"
echo ""
echo "=== 新しいブランチでの状態 ==="
git status --short

echo ""
echo "=== developの状態(参考: 変更が残っていないことの確認) ==="
git log develop -1 --oneline
