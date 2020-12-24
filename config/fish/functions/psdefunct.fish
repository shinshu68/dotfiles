function psdefunct
    ps aux | grep defunct | grep -v grep
end
