FROM ubuntu:24.04

ENV USER=shinshu
ENV HOME=/home/$USER
ENV SHELL=/bin/bash
ENV LANG=ja_JP.UTF-8

# apt のミラーを jaist にする (security.ubuntu.com はそのまま)
RUN sed -i -E 's|^URIs: http://archive\.ubuntu\.com/ubuntu/?$|URIs: http://ftp.jaist.ac.jp/pub/Linux/ubuntu/|' /etc/apt/sources.list.d/ubuntu.sources

# gnupg と software-properties-common は WSL の Ubuntu には最初から入っている (PPA の追加に使う)
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ansible \
    ca-certificates \
    curl \
    git \
    gnupg \
    locales \
    python3-apt \
    software-properties-common \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen $LANG

# playbook の -K で聞かれるパスワードは空のまま Enter で通るようにする
# ubuntu:24.04 には uid 1000 の ubuntu ユーザーがいるので消して、ホストと uid をそろえる
# (マウントしたリポジトリのファイルの所有者が書き換わらないようにするため)
RUN userdel -r ubuntu \
    && useradd -m -s /bin/bash -u 1000 ${USER} \
    && echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER}

USER ${USER}
WORKDIR ${HOME}/dotfiles
