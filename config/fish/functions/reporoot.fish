function reporoot
  set -l super (git rev-parse --show-superproject-working-tree)
  if test $super != "" ^/dev/null >/dev/null
    cd $super
    return
  end
  git rev-parse --show-toplevel ^/dev/null >/dev/null
  if test $status -eq 0
    cd (git rev-parse --show-toplevel)
  else 
    false
  end
end
