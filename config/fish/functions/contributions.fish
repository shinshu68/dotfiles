function contributions
    set -l cmd python3 $HOME/dotfiles/bin/githubcontributions.py $argv
    if set -q TMUX
        tmux set-option default-command "$cmd"
        tmux split-window -l 10
        tmux set-option default-command ""
    else
        eval $cmd
    end
end
