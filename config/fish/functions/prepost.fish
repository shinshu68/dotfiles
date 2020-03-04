function prepost
    if test (count $argv) -ne 1
        false
        return
    end
    python3 $HOME/workspace/prepost/src/prepost.py $argv
end
