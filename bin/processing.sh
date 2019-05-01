#!bin/bash
tmp=`echo pwd -P`
P=`$tmp | sed -e 's/.....//' -e 's/\(^.\)/\1:/' -e 's/\(.\)/\U\1/'`
processing-java.exe --sketch=$P $1
