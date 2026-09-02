#!/usr/bin/env bash
# developブランチとの差分を確認し、PR作成の準備を行うスクリプト。
# - 前提条件のチェック
# - developの最新化
# - 未コミット変更の警告(対象外)
# - コミット一覧/変更ファイル一覧/diffの出力
# - 既存PRのチェック
# - 未pushの場合は自動push
set -uo pipefail

BASE_BRANCH="develop"

fail() {
  echo "ERROR: $1"
  exit 1
}

# 1. Gitリポジトリか
git rev-parse --is-inside-work-tree > /dev/null 2>&1 \
  || fail "現在のディレクトリはGitリポジトリではありません。"

# 2. gh CLIの有無・認証
command -v gh > /dev/null 2>&1 \
  || fail "gh CLIがインストールされていません。https://cli.github.com/ を参照してインストールしてください。"

gh auth status > /dev/null 2>&1 \
  || fail "gh CLIが認証されていません。'gh auth login' を実行してください。"

# 3. 現在のブランチ
CURRENT_BRANCH=$(git branch --show-current)
[ -n "$CURRENT_BRANCH" ] || fail "detached HEAD状態です。作業ブランチにcheckoutしてください。"
[ "$CURRENT_BRANCH" != "$BASE_BRANCH" ] \
  || fail "現在 ${BASE_BRANCH} ブランチにいます。作業用のブランチに切り替えてください。"

echo "現在のブランチ: $CURRENT_BRANCH"

# 4. developを最新化
echo "--- git fetch origin ${BASE_BRANCH} ---"
git fetch origin "$BASE_BRANCH" 2>&1 \
  || fail "リモートの ${BASE_BRANCH} ブランチを取得できませんでした。ブランチが存在するか確認してください。"

git show-ref --verify --quiet "refs/remotes/origin/${BASE_BRANCH}" \
  || fail "リモートに ${BASE_BRANCH} ブランチが見つかりません。"

# 5. 未コミットの変更を警告(対象外・処理は続行)
DIRTY=$(git status --porcelain)
if [ -n "$DIRTY" ]; then
  UNCOMMITTED_COUNT=$(echo "$DIRTY" | wc -l | tr -d ' ')
  echo "NOTE: 未コミットの変更が ${UNCOMMITTED_COUNT} 件あります。これらはPRの差分には含まれません。"
fi

# 6. コミット済み差分の確認(マージベース基準)
MERGE_BASE=$(git merge-base "origin/${BASE_BRANCH}" "$CURRENT_BRANCH") \
  || fail "${BASE_BRANCH} とのマージベースを特定できませんでした。"

DIFF_COMMITS=$(git log --oneline "${MERGE_BASE}..${CURRENT_BRANCH}")

if [ -z "$DIFF_COMMITS" ]; then
  echo "INFO: ${BASE_BRANCH} との差分(コミット)がありません。PRを作成する必要はありません。"
  exit 0
fi

echo "--- コミット一覧 (${BASE_BRANCH}..${CURRENT_BRANCH}) ---"
echo "$DIFF_COMMITS"

echo "--- 変更ファイル一覧 ---"
git diff --stat "${MERGE_BASE}..${CURRENT_BRANCH}"

echo "--- 差分詳細 ---"
git diff "${MERGE_BASE}..${CURRENT_BRANCH}"

# 7. 既存PRの確認
EXISTING_PR=$(gh pr list --head "$CURRENT_BRANCH" --base "$BASE_BRANCH" --json url --jq '.[0].url' 2>/dev/null || echo "")
if [ -n "$EXISTING_PR" ]; then
  echo "EXISTING_PR: $EXISTING_PR"
  exit 0
fi

# 8. push状態の確認、必要なら自動push
git fetch origin "$CURRENT_BRANCH" > /dev/null 2>&1 || true
LOCAL_HASH=$(git rev-parse "$CURRENT_BRANCH")
REMOTE_HASH=$(git rev-parse "origin/${CURRENT_BRANCH}" 2>/dev/null || echo "")

if [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
  echo "--- ローカルブランチをリモートにpushします ---"
  git push -u origin "$CURRENT_BRANCH" 2>&1 || fail "pushに失敗しました。"
else
  echo "ブランチは既にpush済みです。"
fi

echo "READY_FOR_PR"
