#!/bin/bash  
idfilter='https://relay-access.practable.io/session/(\w*)-data' 
access=$(cat /etc/practable/data.access) 
[[ $access =~ $idfilter ]] 
id="${BASH_REMATCH[1]}" 
echo $id
