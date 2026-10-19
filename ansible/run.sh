#!/usr/bin/env bash

set -eu
set -o pipefail

cd "$(dirname "$0")"

# sudo のパスワードを聞き直せる回数
max_tries=3

run_playbook() {
  ansible-playbook \
    -i 'localhost,' \
    "$@" \
    playbook.yml
}

# パスワードなしで sudo できる環境 (Docker の確認用コンテナなど) では聞かない
# -k を付けて、このターミナルに残っている sudo の認証は使わずに確かめる
if sudo -k -n true 2>/dev/null; then
  run_playbook "$@"
  exit
fi

# ansible-playbook の -K は1回しか聞かず、パスワードを間違えると sudo が入力を待ったまま止まる
# (ansible は英語の "Sorry, try again." で間違いを見分けるので、日本語のロケールでは気づけない)
# そのため先に sudo でパスワードを確かめ、間違っていたら聞き直す
for ((i = 1; i <= max_tries; i++)); do
  # 標準入力がスクリプトなどになっていても聞けるように、端末から読む
  IFS= read -rs -p 'BECOME password: ' password < /dev/tty
  echo

  if printf '%s\n' "$password" | sudo -k -S -p '' -v 2>/dev/null; then
    # パスワードがコマンドラインや一時ファイルに残らないように、標準入力で渡す
    printf '%s\n' "$password" | run_playbook --become-password-file=- "$@"
    exit
  fi

  echo "パスワードが違います ($i/$max_tries)" >&2
done

echo "パスワードを $max_tries 回間違えたので終了します" >&2
exit 1
