function fish-link
    set -l files (find $HOME/dotfiles/config/fish | grep '\.fish$')
    set -l len (string length $HOME/dotfiles/config/fish/)
    set -l flag 0

    for f in $files
        set -l file (string sub -s $len $f)
        if not test -f $XDG_CONFIG_HOME/fish$file
            if test $flag -eq 0
                echo "リンク開始"
                set flag 1
            end

            ln -sfv $f $XDG_CONFIG_HOME/fish$file
        end
    end

    set -l broken_links (find $XDG_CONFIG_HOME/fish -xtype l)
    if test (count $broken_links) -ne 0
        echo
        echo "リンク切れのファイルを削除"
        rm -v $broken_links
    end
end

