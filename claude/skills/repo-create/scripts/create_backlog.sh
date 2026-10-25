#!/usr/bin/env bash
# backlog スキルの保存ファイル(~/.claude/backlog-data/<プロジェクト名>.md)を空の状態で作る。
# バックログは WSL 側で一元管理しているので、Windows 側(Git Bash など)から実行された場合も
# WSL の中で作成する。
#
# 使い方:
#   create_backlog.sh <プロジェクト名>     プロジェクト名は GitHub のリポジトリ名を渡す
#
# 出力の最終行:
#   CREATED: <ファイルのパス>    作成した
#   EXISTS: <ファイルのパス>     既にあるので何もしていない(上書きしない)
#   ERROR: <理由>                作成できなかった
#
# 環境変数(主にテスト用):
#   BACKLOG_DATA_DIR  バックログの置き場所(既定: ~/.claude/backlog-data)

set -u

name="${1:-}"
if [[ -z "$name" ]]; then
  echo "ERROR: プロジェクト名を指定してください"
  exit 1
fi
if [[ "$name" == */* || "$name" == .* ]]; then
  echo "ERROR: プロジェクト名として使えない文字が含まれています: $name"
  exit 1
fi

# ---- Windows 側から呼ばれた場合は、WSL に処理を渡す ----
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    if ! command -v wsl.exe >/dev/null 2>&1; then
      echo "ERROR: wsl.exe が見つかりません"
      exit 1
    fi
    export MSYS_NO_PATHCONV=1
    exec wsl.exe -e bash -s -- "$name" < "${BASH_SOURCE[0]}"
    ;;
esac

dir="${BACKLOG_DATA_DIR:-$HOME/.claude/backlog-data}"
file="$dir/$name.md"

if [[ -e "$file" ]]; then
  echo "EXISTS: $file"
  exit 0
fi

mkdir -p "$dir" || { echo "ERROR: フォルダを作成できません: $dir"; exit 1; }

# backlog スキルのフォーマットに合わせ、3つのセクションの見出しだけを置く
cat > "$file" <<'EOF' || { echo "ERROR: ファイルを作成できません: $file"; exit 1; }
# プロジェクトバックログ

## 進行中

## 未着手

## 完了
EOF

echo "CREATED: $file"
