function contributions
    set -l cmd python $HOME/dotfiles/bin/githubcontributions.py
    set -q TMUX
    if test $status -eq 0
        tmux set-option default-command "$cmd"
        tmux split-window -p 25
        tmux set-option default-command ""
    else
        eval $cmd
    end
end
