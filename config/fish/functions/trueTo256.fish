function trueTo256
    if test (count $argv) -ne 1
        false
        return
    end
    python $HOME/dotfiles/bin/truecolorTo256color.py $argv
end
