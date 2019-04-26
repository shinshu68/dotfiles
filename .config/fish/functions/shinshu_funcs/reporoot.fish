function reporoot
  git rev-parse --show-toplevel ^/dev/null >/dev/null
  if test $status -eq 0
    cd (git rev-parse --show-toplevel)
  else 
    false
  end
end
