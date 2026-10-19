# mise で入れた Python・Node などを使えるようにする
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)"
fi
