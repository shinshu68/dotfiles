function __app_installer_discord
    if not test -x /usr/bin/discord
        wget "https://discordapp.com/api/download?platform=linux&format=deb" -O discord-app.deb
        sudo dpkg -i discord-app.deb
        rm discord-app.deb
    end
end
