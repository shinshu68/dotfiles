#!/bin/bash

nvim msgfile.txt

git commit --file='./msgfile.txt'

rm msgfile.txt
