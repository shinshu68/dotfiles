function __app_installer_docker-compose
    if not test -x /usr/local/bin/docker-compose
        curl -L https://github.com/docker/compose/releases/download/1.23.2/docker-compose-`uname -s-uname -m` -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    end
end
