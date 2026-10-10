#!/usr/bin/env bash
#
# sync_and_cleanup.sh
#
# 想定フロー:
#   GitHub上でPRを手動でマージした後に実行する。モードは2つ。
#
#   [通常モード] (引数なし)
#     featureブランチなど → develop のPRをマージした後
#     1. ローカルのdevelopブランチを最新化する (checkout + pull)
#     2. developにマージ済みのローカルブランチを安全に削除する
#        (develop / main / master は保護し、削除しない)
#
#   [バックマージモード] (--back-merge)
#     develop → main のPRをマージした後
#     1. ローカルのmainを最新化する (checkout + pull)
#     2. ローカルのdevelopを最新化する (checkout + pull)
#     3. mainをdevelopにマージする (バックマージ)
#     4. マージしたdevelopをorigin/developにpushする
#     ※ ブランチの削除は行わない。developは削除せず残す。
#     ※ pushが拒否された場合(保護ブランチなど)でも強制pushはしない。
#
# 使い方:
#   bash scripts/sync_and_cleanup.sh
#   bash scripts/sync_and_cleanup.sh --back-merge
#
set -euo pipefail

MODE="normal"
case "${1:-}" in
  "")
    ;;
  --back-merge)
    MODE="back-merge"
    ;;
  *)
    echo "エラー: 不明な引数です: $1 (使えるのは --back-merge のみ)" >&2
    exit 2
    ;;
esac

# 削除対象から除外するブランチ名 (通常モードのみで使用)
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

# developをorigin/developにpushする (強制pushはしない)
push_develop() {
  echo "==> developをorigin/developにpushしています..."
  if ! git push origin develop; then
    echo "エラー: origin/developへのpushに失敗しました。ローカルのdevelopにはバックマージ済みです。" >&2
    echo "(保護ブランチでPRが必要、リモートに新しいコミットがある、などの可能性があります。強制pushはしていません。)" >&2
    exit 1
  fi
}

# gitリポジトリ内かどうかを確認
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "エラー: ここはgitリポジトリではありません。" >&2
  exit 1
fi

# 未コミットの変更がないか確認 (ブランチ切り替え/pull/mergeで事故らないように)
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

# ---------------------------------------------------------------------------
# バックマージモード: main を develop に取り込む
# ---------------------------------------------------------------------------
if [ "$MODE" = "back-merge" ]; then
  # 本流ブランチ名 (main を優先、なければ master)
  if git show-ref --verify --quiet refs/heads/main; then
    TRUNK="main"
  elif git show-ref --verify --quiet refs/heads/master; then
    TRUNK="master"
  else
    echo "エラー: ローカルにmain(またはmaster)ブランチが見つかりません。" >&2
    exit 1
  fi

  echo "==> ${TRUNK}に切り替えています..."
  git checkout "$TRUNK"

  echo "==> origin/${TRUNK}の最新を取り込んでいます..."
  git pull origin "$TRUNK"

  echo "==> developに切り替えています..."
  git checkout develop

  echo "==> origin/developの最新を取り込んでいます..."
  git pull origin develop

  echo "==> ${TRUNK}をdevelopにマージしています (バックマージ)..."
  if git merge-base --is-ancestor "$TRUNK" develop; then
    echo "==> developは既に${TRUNK}の内容を含んでいます。マージは不要でした。"
    push_develop
    echo "==> 完了しました。"
    exit 0
  fi

  if ! git merge "$TRUNK" --no-edit; then
    echo "エラー: ${TRUNK}をdevelopにマージする際にコンフリクトが発生しました。" >&2
    echo "コンフリクトしたファイル:" >&2
    git diff --name-only --diff-filter=U | sed 's/^/    - /' >&2
    # 中途半端な状態を残さないため、マージを取り消してdevelopを元に戻す
    git merge --abort
    echo "マージを取り消し、developを元の状態に戻しました。手動でマージして解消してください。" >&2
    exit 1
  fi

  echo "==> ${TRUNK}をdevelopにマージしました。developは削除していません。"
  push_develop
  echo "==> 完了しました。"
  exit 0
fi

# ---------------------------------------------------------------------------
# 通常モード: develop を最新化し、マージ済みローカルブランチを削除
# ---------------------------------------------------------------------------
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
