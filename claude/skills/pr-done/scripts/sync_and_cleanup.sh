#!/usr/bin/env bash
#
# sync_and_cleanup.sh
#
# 想定フロー:
#   1. GitHub上でPRを手動でマージした後に実行する
#   2. ローカルのdevelopブランチを最新化する (checkout + pull)
#   3. developにマージ済みのローカルブランチを安全に削除する
#      (develop / main / master は保護し、削除しない)
#
# 使い方:
#   bash scripts/sync_and_cleanup.sh
#
set -euo pipefail

# 削除対象から除外するブランチ名
PROTECTED_BRANCHES=("develop" "main" "master")

is_protected() {
  local branch="$1"
  for p in "${PROTECTED_BRANCHES[@]}"; do
    if [[ "$branch" == "$p" ]]; then
      return 0
    fi
  done
  return 1
}

# gitリポジトリ内かどうかを確認
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "エラー: ここはgitリポジトリではありません。" >&2
  exit 1
fi

# 未コミットの変更がないか確認 (developへの切り替え/pullで事故らないように)
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "エラー: コミットされていない変更があります。コミットまたはstashしてから再実行してください。" >&2
  git status --short
  exit 1
fi

# developブランチが存在するか確認
if ! git show-ref --verify --quiet refs/heads/develop; then
  echo "エラー: ローカルにdevelopブランチが見つかりません。" >&2
  exit 1
fi

echo "==> developに切り替えています..."
git checkout develop

echo "==> origin/developの最新を取り込んでいます..."
git pull origin develop

echo "==> developにマージ済みのローカルブランチを確認しています..."
# 現在のブランチ(*付き)を除去し、前後の空白をトリム
merged_branches=$(git branch --merged develop | sed 's/^[* ]*//')

to_delete=()
while IFS= read -r branch; do
  [ -z "$branch" ] && continue
  if is_protected "$branch"; then
    continue
  fi
  to_delete+=("$branch")
done <<< "$merged_branches"

if [ "${#to_delete[@]}" -eq 0 ]; then
  echo "==> 削除対象のブランチはありませんでした。"
  echo "==> 完了しました。"
  exit 0
fi

echo "==> 以下のマージ済みブランチを削除します:"
printf '    - %s\n' "${to_delete[@]}"

for branch in "${to_delete[@]}"; do
  # -d は「安全な削除」で、developにマージされていないブランチは削除できない
  git branch -d "$branch"
done

echo "==> 完了しました。"
