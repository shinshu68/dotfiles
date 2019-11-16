function app_installer
    set -l apps "all docker docker-compose rootless-docker google-chrome vivaldi slack"
    set apps (string split ' ' $apps)

    if test (count $argv) -eq 0
        false
        return
    end

    if test (count $argv) -eq 1
        if test $argv = all
            for app in $apps
                __app_installer_$app
            end
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
