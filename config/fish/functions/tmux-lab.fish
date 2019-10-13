function tmux-lab
    if not set -q TMUX
        false
        return
    end

    set -l c (count (string split '\n' (tmux list-panes)))
    if test $c -ne 1
        false
        return
    end

    tmux split-pane -v -l (math $LINES -8) -t 0
    tmux split-pane -h -l 30 -t 0
    tmux clock-mode -t 1
    tmux select-pane -t 2
end
