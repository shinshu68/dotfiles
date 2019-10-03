FROM ubuntu:18.04

# aptのサーバを日本のミラーにする
RUN sed -i".back" -e 's/\/\/archive.ubuntu.com/\/\/ftp.jaist.ac.jp\/pub\/Linux/g' /etc/apt/sources.list

RUN apt add-repository ppa:fish-shell/release-3

RUN apt-get update && apt-get install -y \
    python3 \
    neovim \
    fish
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
