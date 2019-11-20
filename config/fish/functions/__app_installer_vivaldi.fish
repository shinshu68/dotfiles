function __app_installer_vivaldi
    if not test -x /usr/bin/vivaldi
        wget https://downloads.vivaldi.com/stable/vivaldi-stable_2.3.1440.41-1_amd64.deb
        sudo dpkg -i vivaldi-stable_2.3.1440.41-1_amd64.deb
        if test $status -ne 0
            sudo apt install --fix-broken
        end
        rm vivaldi-stable_2.3.1440.41-1_amd64.deb
    end
end
