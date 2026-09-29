FROM ubuntu:24.04

ENV USER=shinshu
ENV HOME=/home/$USER
ENV SHELL=/bin/bash

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash ${USER} \
    && echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER}

USER ${USER}
WORKDIR ${HOME}
