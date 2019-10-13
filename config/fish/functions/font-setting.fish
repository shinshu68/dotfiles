function font-setting
    cd ~/Downloads
    curl -LO https://github.com/miiton/Cica/releases/download/v5.0.1/Cica_v5.0.1_with_emoji.zip
    unzip Cica_v5.0.1_with_emoji.zip
    cp -f *.ttf ~/.local/share/fonts

    fc-cache -fv

    gsettings set org.gnome.desktop.interface monospace-font-name 'Cica 12'
    gsettings set org.gnome.desktop.interface document-font-name 'Cica 12'
    gsettings set org.gnome.desktop.interface font-name 'Cica 12'

    cd
end

