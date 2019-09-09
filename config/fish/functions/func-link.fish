function func-link
    set -l func (find $HOME/dotfiles/config/fish | grep '\.fish$')
    set -l len (string length $HOME/dotfiles/config/fish/)
    for f in $func
        set -l file (string sub -s $len $f)
        ln -sfv $f $XDG_CONFIG_HOME/fish$file
    end
end

