function git-yesterday
    git rev-parse --show-toplevel 2>/dev/null >/dev/null
    if test $status -ne 0
        false
    end

    git log | grep "^Date:" | grep (date --date "-1 days" +"%a %b %d") 2>/dev/null >/dev/null
    if test $status -eq 0
        echo "Yesterday commit exists."
        return
    end

    set -l date (before-date-git-style 1)
    git rebase -i HEAD~1
    git commit --amend --date="$date"
    git rebase --continue
    git rebase HEAD~1 --committer-date-is-author-date
end
