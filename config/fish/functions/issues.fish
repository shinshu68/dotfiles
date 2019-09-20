function issues
    git rev-parse --show-toplevel 2>/dev/null >/dev/null
    if test $status -ne 0
        false
        return
    end

    set -l issue (python $HOME/dotfiles/bin/githubissues.py | fzf-tmux -d $FZF_TMUX_HEIGHT)
    if test $status -ne 0
        true
        return
    end
    set -l issue_number (echo $issue | awk '{print $1}')
    python $HOME/dotfiles/bin/githubissues.py $issue_number
end
