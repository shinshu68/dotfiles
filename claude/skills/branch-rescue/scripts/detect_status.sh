#!/usr/bin/env bash
#
# detect_status.sh
#
# 想定フロー:
#   誤って develop ブランチのまま作業・変更してしまった状態を検出し、
#   ブランチ名を判断するために必要な情報(diff・変更ファイル・既存ブランチの命名傾向)を出力する。
#   ここではブランチの作成は行わない(判断材料を集めるだけ)。
#
# 使い方:
#   bash scripts/detect_status.sh
#
set -euo pipefail

# gitリポジトリ内かどうかを確認
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "ERROR: ここはgitリポジトリではありません。" >&2
  exit 1
fi

current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")

if [ -z "$current_branch" ]; then
  echo "ERROR: 現在detached HEAD状態です。まずブランチに切り替えてから実行してください。" >&2
  exit 1
fi

if [ "$current_branch" != "develop" ]; then
  echo "NOT_ON_DEVELOP:${current_branch}"
  exit 0
fi

# 未コミットの変更(staged / unstaged / untracked)があるか確認
has_staged=1
git diff --cached --quiet || has_staged=0
has_unstaged=1
git diff --quiet || has_unstaged=0
untracked="$(git ls-files --others --exclude-standard)"

if [ "$has_staged" -eq 1 ] && [ "$has_unstaged" -eq 1 ] && [ -z "$untracked" ]; then
  echo "NO_CHANGES"
  exit 0
fi

echo "=== CURRENT_BRANCH ==="
echo "$current_branch"

echo ""
echo "=== EXISTING_BRANCHES (命名規則の参考用) ==="
# マージ済みブランチを削除する運用のリポジトリでは、ここはmain/develop程度しか
# 残っていないことが多い。その場合は空でも異常ではないので、次の
# RECENT_COMMIT_MESSAGES を命名規則の判断材料として使う。
git branch -a --format='%(refname:short)' | grep -v '^develop$' | grep -v -- '->' || true

echo ""
echo "=== RECENT_COMMIT_MESSAGES (命名規則の参考用) ==="
# ブランチ自体は消えていても、コミットメッセージの接頭辞(feat:/fix:等の
# Conventional Commits風の運用など)は履歴に残るため、こちらも規則の手がかりになる
git log develop -20 --oneline || true

echo ""
echo "=== STATUS (short) ==="
git status --short

echo ""
echo "=== STAGED DIFF STAT ==="
git diff --cached --stat || true

echo ""
echo "=== UNSTAGED DIFF STAT ==="
git diff --stat || true

echo ""
echo "=== STAGED DIFF ==="
git diff --cached || true

echo ""
echo "=== UNSTAGED DIFF ==="
git diff || true

echo ""
echo "=== UNTRACKED FILES ==="
if [ -n "$untracked" ]; then
  echo "$untracked"
else
  echo "(なし)"
fi

echo ""
echo "READY_FOR_ANALYSIS"
