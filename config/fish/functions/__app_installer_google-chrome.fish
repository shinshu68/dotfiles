function __app_installer_google-chrome
    if not test -x /usr/bin/google-chrome
        curl https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
        echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | sudo tee /etc/apt/sources.list.d/google-chrome.list
        sudo apt update
        sudo apt install google-chrome-stable
        if test $status -ne 0
            sudo apt install --fix-broken
        end
    end
end
