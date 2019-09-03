function func-link
    if test (count $argv) -ne 1
        false
        return
    end
    set -l func (find $HOME/dotfiles/config/fish | grep '\.fish$' | grep -F "$argv")
    set -l len (string length $HOME/dotfiles/config/fish/)
    if test (count $func) -eq 1 
        set -l file (string sub -s $len $func)
        ln -sfv $func $XDG_CONFIG_HOME/fish$file
    else
        for f in $func
            echo $f
        end
        false
    end
end

