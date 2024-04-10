#!/bin/bash
set -x
cat .jci.pids |
{
while read -r pid 
do
    kill -15 $pid
done
}
