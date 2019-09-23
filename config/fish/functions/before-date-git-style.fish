function before-date-git-style
    if test (count $argv) -ne 1
        false
        return
    end
    date --date "-$argv day" +"%c %z"
end
