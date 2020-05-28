function date-to-unix-time
    if test (count $argv) -ne 1
        false
        return
    end

    set -l unix_time (date -d $argv +"%s")
    echo $unix_time
end
