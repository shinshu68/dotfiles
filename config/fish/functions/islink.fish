function islink
    if test (count $argv) -ne 1
        false
        return
    end
    test -L $argv
end
