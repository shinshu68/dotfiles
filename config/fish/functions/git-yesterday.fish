function git-yesterday
    git rev-parse --show-toplevel 2>/dev/null >/dev/null
    if test $status -ne 0
        false
    end
    set -l date (before-date-git-style 1)
    git rebase -i HEAD~1
    git commit --amend --date="$date"
    git rebase --continue
    git rebase HEAD~1 --committer-date-is-author-date
end
