function prepost
    if test (count $argv) -ne 1
        false
        return
    end
    python3 ~/workspace/prepost/src/prepost.py $argv
end

complete -c prepost -x -a "pre post"
