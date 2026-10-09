#!/usr/bin/env bash
# リポジトリ作成前の状態確認(git init 前のディレクトリで実行する)
# ERROR: で始まる行が出たら処理を止める

# gh の確認
if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI がインストールされていません"
  exit 1
fi
if ! gh auth status >/dev/null 2>&1; then
  echo "ERROR: gh が未認証です。gh auth login を実行してください"
  exit 1
fi
echo "GH_USER: $(gh api user --jq .login 2>/dev/null)"

# git のユーザー設定(コミットに必要)
if [ -z "$(git config user.name)" ] || [ -z "$(git config user.email)" ]; then
  echo "ERROR: git の user.name / user.email が設定されていません"
  exit 1
fi

# まだ Git リポジトリでないこと(親ディレクトリがリポジトリの場合も検出する)
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: 既に Git リポジトリの中です ($(git rev-parse --show-toplevel))"
  exit 1
fi

echo "DIR_NAME: $(basename "$(pwd)")"

# 名前と説明文を決める材料
for f in CLAUDE.md docs/plan.md; do
  if [ -f "$f" ]; then
    echo "===== $f (先頭80行) ====="
    head -n 80 "$f"
  else
    echo "WARNING: $f がありません"
  fi
done

echo "READY"
