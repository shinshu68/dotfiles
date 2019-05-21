function histoday
    history --show-time='%Y%m%d' | grep (today) | sed -e "s/^[0-9]\+//" | less 
end
