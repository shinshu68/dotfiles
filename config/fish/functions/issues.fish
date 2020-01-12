function issues
    if not is-inside-git-dir
        false
        return
    end
    python3 $HOME/dotfiles/bin/get_github_issues.py
    set -l issue (python3 $HOME/dotfiles/bin/print_issues.py | fzf-tmux -d $FZF_TMUX_HEIGHT)
    if test $status -ne 0
        true
        return
    end
    set -l issue_number (echo $issue | awk '{print $1}')
    python3 $HOME/dotfiles/bin/print_issues.py $issue_number
end
