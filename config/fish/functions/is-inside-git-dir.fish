function is-inside-git-dir
    git rev-parse --show-toplevel 2>/dev/null >/dev/null
    if test $status -ne 0
        false
    else
        true
    end
end
