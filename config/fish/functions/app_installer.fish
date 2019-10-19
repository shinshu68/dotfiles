set -g apps docker docker-compose rootless-docker google-chrome vivaldi slack
function app_installer
    if test (count $argv) -eq 1
        if test $argv = all
            echo all
            return
        end
    end

    for arg in $argv
        if contains $arg $apps
            __app_installer_$arg
        else
            echo ng
        end
    end
end

set apps all $apps
set apps (echo $apps | string join ' ')
complete --command app_installer -x -a $apps
