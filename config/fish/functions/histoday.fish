function histoday
    history --show-time='%Y%m%d%s' | grep (today) | sort | sed -e "s/^[0-9]\+//" | less 
end
