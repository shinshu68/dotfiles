function __app_installer_slack
    if not test -x /usr/bin/slack
        wget https://downloads.slack-edge.com/linux_releases/slack-desktop-4.1.1-amd64.deb
        sudo dpkg -i slack-desktop-4.1.1-amd64.deb
        if test $status -ne 0
            sudo apt install --fix-broken
        end
        rm slack-desktop-4.1.1-amd64.deb
    end
end
