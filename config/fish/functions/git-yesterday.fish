function git-yesterday
    if not is-inside-git-dir
        false
        return
    end

    if test (git diff --numstat | wc -l) -ne 0
        echo error: has untracked files
        false
        return
    end

    set -l before_date 1
    if test (count $argv) -eq 1
        set before_date $argv
    end

    set -l date_str "-"$before_date" days"

    set -l target_commit_date (string join ' ' (string split ' ' (git log | grep "^Date:" | head -n 2 | tail -n 1))[4..8])
    set -l unix_time (date-to-unix-time $target_commit_date)

    if test (math (date -d $date_str +"%s") - $unix_time) -lt '0'
        echo invalid value $date_str \((date -d $date_str)\)
        false
        return
    end

    set -l date (before-date-git-style $before_date)
    read -p'echo "Change Commit Date to \"$date\" ? [y/n] "' -l yn
    if test $yn != 'y'
        return
    end

    git rebase -i HEAD~1
    git commit --amend --date="$date"
    git rebase --continue
    git rebase HEAD~1 --committer-date-is-author-date
end
