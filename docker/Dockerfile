FROM ubuntu:18.04

# aptのサーバを日本のミラーにする
RUN sed -i".back" -e 's/\/\/archive.ubuntu.com/\/\/ftp.jaist.ac.jp\/pub\/Linux/g' /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg |  apt-key add -

RUN add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"

RUN add-apt-repository ppa:fish-shell/release-3

RUN apt-get update && apt-get install -y \
    direnv \
    docker-ce \
    fish \
    git \
    neovim \
    python3 \
    tmux \
    tree \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
