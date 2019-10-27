function __app_installer_docker
    if not test -x /usr/bin/docker
        sudo apt-get install apt-transport-https ca-certificates
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
        sudo apt-get install docker-ce
        sudo systemctl start docker
    end
end
