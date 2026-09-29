#!/usr/bin/env bash

set -eu
set -o pipefail

cd "$(dirname "$0")"

ansible-playbook \
  -i 'localhost,' \
  --extra-vars='@config.yml' \
  -K \
  "$@" \
  playbook.yml
