FROM ubuntu:18.04

ENV USER shinshu
ENV HOME /home/$USER
ENV SHELL /bin/bash

RUN sed -i".back" -e 's/\/\/archive.ubuntu.com/\/\/ftp.jaist.ac.jp\/pub\/Linux/g' /etc/apt/sources.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common

RUN apt-add-repository --yes --update ppa:ansible/ansible

RUN apt-get update && apt-get install -y --no-install-recommends \
    ansible \
    curl \
    git \
    sudo \
    locales \
    python-apt \
    libasound2

ENV LANG ja_JP.UTF-8
RUN locale-gen $LANG

RUN useradd -m ${USER}
RUN gpasswd -a ${USER} sudo
RUN echo "${USER}:${USER}" | chpasswd

USER ${USER}
WORKDIR ${HOME}

RUN git clone https://github.com/shinshu68/dotfiles.git
