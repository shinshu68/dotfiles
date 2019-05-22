function histoday
    set day (today)
    history --show-time='%Y%m%d%s ' | grep -E "^$day" | sort | sed -e "s/^[0-9]\+ //" | less -N
end
