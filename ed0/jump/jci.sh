#!/bin/bash
# start jump clients for a group of hosts in an ansible inventory
# usage jci.sh <inventory.yaml> <group>
export INVENTORY=$1
export GROUP=$2
set -x
cat "$INVENTORY" | yq ".$GROUP.[]" | yq 'keys' | yq '.[] | sub("-","")' |
    {
     pids=()
while read -r expt 
do 
    port=$(cat "$INVENTORY" | yq ".$GROUP.[].$expt.ansible_port")
    #user=$(cat "$INVENTORY" | yq ".$GROUP.[].$expt.ansible_user")
    #pass=$(cat "$INVENTORY" | yq ".$GROUP.[].$expt.ansible_password")
    #host=$(cat "$INVENTORY" | yq ".$GROUP.[].$expt.ansible_host")
    #echo "$expt $user@$host:$port/$pass"
    pid=$(./jc.sh $expt $port)
    #pid=$!
    pids+=($pid)
done
#echo "${pids[*]}" > .jci.pids
printf '%s\n' "${pids[@]}" > .jci.pids
}
#cat .jci.pids


