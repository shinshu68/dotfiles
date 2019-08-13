function contributions
    tmux split-window -p 25
    tmux send-keys "python $HOME/dotfiles/bin/githubcontributions.py" C-m
end
