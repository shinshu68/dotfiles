function today
    if test -n "$argv"
        if test $argv -lt 0
            date --date "$argv day" "+%Y%m%d"
        end
    else
        date "+%Y%m%d"
    end
end
