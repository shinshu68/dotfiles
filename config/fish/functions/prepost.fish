function prepost
    if test (count $argv) -ne 1
        false
        return
    end
    python ~/workspace/prepost/prepost.py $argv
end
