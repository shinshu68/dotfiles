function input
    set -l p (git rev-parse --show-toplevel)
    set -l clipboard (powershell.exe -command 'Get-Clipboard' | string trim)
    echo $clipboard > $p/input.txt
end
