function reporoot
    if not is-inside-git-dir
        false
        return
    end

    cd (__reporoot_str)
end
