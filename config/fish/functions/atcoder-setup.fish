function atcoder-setup --description 'リポジトリルートの template.cpp を複数コピー'
    set -l root (git rev-parse --show-toplevel); or return 1
    set -l tmpl $root/template.cpp
    if not test -f $tmpl
        echo "template.cpp が見つかりません: $tmpl" >&2
        return 1
    end

    set -l names $argv
    test (count $names) -eq 0; and set names a b c d

    for n in $names
        if test -e $n.cpp
            echo "スキップ: $n.cpp は既に存在します" >&2
        else
            cp $tmpl $n.cpp
        end
    end
end