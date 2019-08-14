function contributions
    set -l cmd python $HOME/dotfiles/bin/githubcontributions.py
    set -q TMUX
    if test $status -eq 0
        tmux set-option default-command "$cmd"
        # set -l panes (string split ' ' (tmux list-panes | sed -e 's/:.*%[0-9]\+//g'))
        # set -l active_pane 0
        # set -l tmp ''
        # for pane in $panes
        #     if test $tmp = '(active)'
        #         break
        #     end
        #     set active_pane $tmp
        #     set tmp $pane
        # end
        tmux select-pane -t 0
        tmux split-window -l 10
        # tmux split-window -l (expr $LINES - 10)
        # tmux swap-pane -s 1 -t 0
        # tmux select-pane -t 0
        tmux set-option default-command ""
    else
        eval $cmd
    end
end
