#!/bin/sh

if [[ ! -f $1 ]];then
    echo "Please input tags list file."
    exit
fi
for line in `cat $1`
do
    ./fetch_chromium_tag.sh $line
done