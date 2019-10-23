function is_exists
    if test (count $argv) -ne 1
        false
        return
    end
    which $args
end
