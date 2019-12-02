FROM ubuntu:18.04

# aptのサーバを日本のミラーにする
RUN sed -i".back" -e 's/\/\/archive.ubuntu.com/\/\/ftp.jaist.ac.jp\/pub\/Linux/g' /etc/apt/sources.list

ENV DEBIAN_FRONTEND=noninteractive

# dockerのインストールのためのパッケージを追加する
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# dockerのリポジトリキーをダウンロード
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg |  apt-key add -

# docker fish neovim ansibleのリポジトリを追加
RUN add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable" \
 && add-apt-repository ppa:ansible/ansible \
 && add-apt-repository ppa:fish-shell/release-3 \
 && add-apt-repository ppa:neovim-ppa/stable

# 必要なパッケージのインストール
RUN apt-get update && apt-get install -y \
    ansible \
    build-essential \
    cmake \
    curl \
    direnv \
    docker-ce \
    fish \
    git \
    gosu \
    libbz2-dev \
    libclang-6.0-dev \
    libffi-dev \
    liblzma-dev \
    libncurses5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    libxml2-dev \
    libxmlsec1-dev \
    llvm \
    locales \
    make \
    neovim \
    python \
    python-pip \
    python3 \
    python3-pip \
    sudo \
    time \
    tk-dev \
    tmux \
    tree \
    tzdata \
    wget \
    xz-utils \
    zlib1g-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# docker-composeのインストール
RUN curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
 && chmod +x /usr/local/bin/docker-compose

# emojifyのインストール
RUN sh -c "curl https://raw.githubusercontent.com/mrowa44/emojify/master/emojify -o /usr/local/bin/emojify && chmod +x /usr/local/bin/emojify"

# localeを生成
RUN locale-gen ja_JP.UTF-8 \
 && localedef -f UTF-8 -i ja_JP ja_JP

# 環境変数を設定
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:jp
ENV LC_ALL ja_JP.UTF-8
ENV TZ Asia/Tokyo

# ENTRYPOINTの設定
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
