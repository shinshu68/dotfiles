function func-link
    set -l func (find $HOME/dotfiles/config/fish | grep '\.fish$')
    set -l len (string length $HOME/dotfiles/config/fish/)

    echo "リンク開始"
    for f in $func
        set -l file (string sub -s $len $f)
        ln -sfv $f $XDG_CONFIG_HOME/fish$file
    end

    set -l broken_links (find $XDG_CONFIG_HOME/fish -xtype l)
    if test (count $broken_links) -ne 0
        echo
        echo "リンク切れのファイルを削除"
        rm -v $broken_links
    end

    # find $XDG_CONFIG_HOME/fish -xtype l | xargs rm -v
end

