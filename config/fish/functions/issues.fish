function issues
    if not is-inside-git-dir
        false
        return
    end

    set -l issue (python3 $HOME/dotfiles/bin/githubissues.py | fzf-tmux -d $FZF_TMUX_HEIGHT)
    if test $status -ne 0
        true
        return
    end
    set -l issue_number (echo $issue | awk '{print $1}')
    python3 $HOME/dotfiles/bin/githubissues.py $issue_number
end
