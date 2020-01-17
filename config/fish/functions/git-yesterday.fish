function git-yesterday
    if not is-inside-git-dir
        false
        return
    end

    set -l before_date 1
    if test (count $argv) -eq 1
        set before_date $argv
    end

    git log | grep "^Date:" | grep (date --date "-1 days" +"%a %b %d") 2>/dev/null >/dev/null
    if test $status -eq 0
        echo "Yesterday commit exists."
        return
    end

    set -l date (before-date-git-style $before_date)
    git rebase -i HEAD~1
    git commit --amend --date="$date"
    git rebase --continue
    git rebase HEAD~1 --committer-date-is-author-date
end
