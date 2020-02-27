function contributions
    set -l cmd python3 $HOME/dotfiles/bin/github_contributions.py $argv
    if set -q TMUX
        tmux set-option default-command "$cmd"
        tmux split-window -l 10
        tmux set-option default-command ""
    else
        eval $cmd
    end
end
