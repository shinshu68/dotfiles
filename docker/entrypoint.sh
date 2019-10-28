#!/bin/bash

USER_ID=${UID}
GROUP_ID=${GID}
USER_NAME=${USERNAME}

echo "Starting with UID : $USER_ID, GID: $GROUP_ID $USER_NAME $@"

users | grep $USER_NAME >/dev/null 2>&1
if [ $? != 0 ]; then
    useradd -u $USER_ID -o -m -s /usr/bin/fish $USER_NAME
    export HOME=/home/$USER_NAME
    gpasswd -a $USER_NAME docker
fi

exec /usr/sbin/gosu $USER_NAME "$@"
