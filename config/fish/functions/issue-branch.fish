function issue-branch
    if not is-inside-git-dir
        false
        return
    end

    if not test -f $HOME/dotfiles/bin/.issue_data
        python3 $HOME/dotfiles/bin/get_github_issues.py
    end

    set -l issue (python3 $HOME/dotfiles/bin/print_issues.py | fzf-tmux -d $FZF_TMUX_HEIGHT)
    if test $status -ne 0
        true
        return
    end
    set -l issue_branch issue-\#(echo $issue | awk '{print $1}')

    git branch -a | grep -q $issue_branch
    if test $status -eq 0
        git checkout -q $issue_branch
    else
        git checkout -b $issue_branch
    end

end
