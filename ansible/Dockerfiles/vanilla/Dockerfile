FROM ubuntu:18.04

ENV USER shinshu
ENV HOME /home/$USER
ENV SHELL /bin/bash

RUN sed -i".back" -e 's/\/\/archive.ubuntu.com/\/\/ftp.jaist.ac.jp\/pub\/Linux/g' /etc/apt/sources.list

RUN useradd -m ${USER}
RUN gpasswd -a ${USER} sudo
RUN echo "${USER}:${USER}" | chpasswd

USER ${USER}
WORKDIR ${HOME}
