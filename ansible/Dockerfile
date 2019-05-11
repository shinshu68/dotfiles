# FROM ubuntu:18.04
FROM elementary/docker:stable

ENV USER shinshu
ENV HOME /home/${USER}
ENV SHELL /bin/bash

RUN \
  apt update && \
  apt install -y \
    sudo \
    curl \
    vim \
    python \
    python3 \
    python-apt

# 一般ユーザアカウントを追加
RUN useradd -m ${USER}
# 一般ユーザにsudo権限を付与
RUN gpasswd -a ${USER} sudo
# 一般ユーザのパスワード設定
RUN echo "${USER}:shinshu" | chpasswd

USER ${USER}

WORKDIR ${HOME}

ENTRYPOINT ["/bin/bash"]
