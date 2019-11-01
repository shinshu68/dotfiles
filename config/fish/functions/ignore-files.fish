function ignore-files
    git rev-parse --show-toplevel 2>/dev/null >/dev/null
    if test $status -ne 0
        false
        return
    end

    set -l files (find . -type d -name .git -prune -o -type f -name "*" | sed "s!^./!!")
    set -l ignore_files (git ls-files -i -o --exclude-standard)

    for file in $files
        set -l flag 0
        for ignore_file in $ignore_files
            if test $file = $ignore_file
                set flag 1
            end
        end
        if test $flag -eq 0
            echo $file
        else
            echo -e $file '(\x1b[38;2;255;0;0mignored\x1b[0m)'
        end
    end
end
