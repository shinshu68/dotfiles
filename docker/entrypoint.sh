#!/bin/bash

echo "Starting with UID : $USER_ID, GID: $GROUP_ID $@"
useradd -u $USER_ID -o -m -s /usr/bin/fish shinshu
export HOME=/home/shinshu
gpasswd -a shinshu docker

exec /usr/sbin/gosu shinshu "$@"
