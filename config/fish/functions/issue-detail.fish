function issue-detail
    if not is-inside-git-dir
        false
        return
    end

    set -l branch (git symbolic-ref --short HEAD)

    if not string match -q 'issue-#*' $branch
        false
        return
    end

    if not test -f $HOME/dotfiles/bin/.issue_data
        python3 $HOME/dotfiles/bin/get_github_issues.py
    end

    set -l issue_number (string sub -s (math (string length 'issue-#') + 1) $branch)

    python3 $HOME/dotfiles/bin/print_issues.py $issue_number
end
