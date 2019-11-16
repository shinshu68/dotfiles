function __app_installer_rootless-docker
    if not test -x $HOME/bin/docker
        curl -sSL https://get.docker.com/rootless | sh
    end
end
