#!/usr/bin/env bash
# collect.sh の一覧を Markdown ファイルに書き出して VSCode で開き、同じ一覧を標準出力にも出す。
# 書き出すのはこのファイルだけで、リポジトリやバックログは変更しない。
#
# 使い方:
#   preview.sh [--all] [絞り込み文字列]    引数は collect.sh にそのまま渡す
#
# 書き出し先 (毎回上書きする):
#   WSL                ~/.cache/pj-status/latest.md
#   Windows (Git Bash) %TEMP%\pj-status\latest.md
#
# 環境変数(主にテスト用):
#   PJ_STATUS_OUT   書き出し先のパス

set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

output="$(bash "$script_dir/collect.sh" "$@")"
status=$?
printf '%s\n' "$output"

# 設定ファイルが無い・対象が0件などの案内は一覧ではないので、書き出しも表示もしない
if (( status != 0 )) || [[ "$output" != "## プロジェクト進捗"* ]]; then
  exit "$status"
fi

# Windows から実行したときは、Windows の VSCode が WSL のパスを開けないため Windows 側に書く
is_windows=false
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) is_windows=true ;;
esac

if [[ -n "${PJ_STATUS_OUT:-}" ]]; then
  out="$PJ_STATUS_OUT"
elif $is_windows; then
  out="${TEMP:-/tmp}/pj-status/latest.md"
else
  out="$HOME/.cache/pj-status/latest.md"
fi

if ! mkdir -p "$(dirname "$out")" || ! printf '%s\n' "$output" > "$out"; then
  echo "一覧をファイルに書き出せませんでした: $out" >&2
  exit 0
fi

open_path="$out"
$is_windows && command -v cygpath >/dev/null 2>&1 && open_path="$(cygpath -w "$out")"

open_in_vscode() {
  code --reuse-window "$1" >/dev/null 2>&1 && return 0
  $is_windows && return 1
  # WSL の remote-cli は VSCODE_IPC_HOOK_CLI のソケットが無いと失敗するので、Windows 側の code に切り替える
  local windows_code
  windows_code="$(type -ap code | grep -m1 '^/mnt/')" || return 1
  env -u VSCODE_IPC_HOOK_CLI "$windows_code" --reuse-window "$1" >/dev/null 2>&1
}

if ! command -v code >/dev/null 2>&1; then
  echo "VSCode で開けませんでした (code コマンドが見つかりません)。一覧は次のファイルに書き出しています: $open_path" >&2
elif ! open_in_vscode "$open_path"; then
  echo "VSCode で開けませんでした (code コマンドが失敗しました)。一覧は次のファイルに書き出しています: $open_path" >&2
else
  echo "VSCode で一覧を開きました: $open_path" >&2
fi
exit 0
