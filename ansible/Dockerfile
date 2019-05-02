# FROM ubuntu:18.04
FROM elementary/docker:stable

RUN \
  apt update && \
  apt install -y \
    sudo \
    curl \
    python \
    python3 \
    python-apt

ENTRYPOINT ["/bin/bash"]
