#!/bin/bash 
pwd=`pwd`
for d in */ .*/ ..*/; do
    cd $pwd/$d
    echo $pwd/$d
    find . -type f | wc -l
done
