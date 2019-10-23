function is_exists
    if test (count $argv) -ne 1
        false
        return
    end
    which $argv 2>/dev/null >/dev/null
end
