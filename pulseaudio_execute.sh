#!/bin/bash

cd /mnt/d/pulseaudio-1.1/bin

while ./pulseaudio.exe > nul 2>&1 || true; do
    echo 'restart' > /dev/null 2&>1
done

