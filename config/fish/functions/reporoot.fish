function __reporoot_str
    set -l super (git rev-parse --show-superproject-working-tree 2>/dev/null)
    if test $status -eq 0 -a "$super" != ""
        echo $super
        return
    end

    set -l reporoot (git rev-parse --show-toplevel 2>/dev/null)
    if test $status -eq 0
        echo $reporoot
        return
    end

    false
end

function reporoot
    if not is-inside-git-dir
        false
        return
    end

    cd (__reporoot_str)
end
