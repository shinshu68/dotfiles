function ignore-tree
    git rev-parse --show-toplevel 2>/dev/null >/dev/null
    if test $status -ne 0
        false
        return
    end

    set -l tree (tree -aCI "*.git*" .)
    set -l files (tree -afCI "*.git*" . | awk '{print $NF}')[1..-3] # 最後の2行は使用しないので消す
    set -l ignore_files (git ls-files -i -o --exclude-standard)

    set -l out ""
    for i in (seq (count $files))
        set -l flag 0
        for ignore_file in $ignore_files
            if test $files[$i] = ./$ignore_file
                set flag 1
            end
        end

        if test $flag -eq 0
            # echo $tree[$i]
            set out $out$tree[$i]'\n'
        else
            # echo -e $tree[$i] '(\x1b[38;2;255;0;0mignore\x1b[0m)'
            set out $out$tree[$i]'(\x1b[38;2;255;0;0mignore\x1b[0m)\n'
        end
    end
    echo -e $out
    echo $tree[-2]
    echo $tree[-1]
end
