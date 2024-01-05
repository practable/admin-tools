#!/bin/bash

if [ -z $1 ]
then
	printf "usage: experiment-clients <group-name>\n"
	exit
fi

# usage: ./experiment-clients <asnible-group>
# read ansible inventory file and start clients for a group of hosts
GROUP=$1
HOSTS=$(ansible-inventory --list | jq -r ".${GROUP}.hosts[]")

pids=() #store pid of jump clients so we can stop them on exit
for host in $HOSTS
do

   #echo $host	
   info=$(ansible-inventory --host $host | jq -c '.')
   echo $info
   port=$(echo $info | jq -r '.ansible_port')
   token=$(echo $info | jq -r '.practable_token')
   url=$(echo $info | jq -r '.practable_url')
   export JUMP_BASE_PATH=/api/v1 
   export JUMP_CLIENT_LOCAL_PORT=$port
   export JUMP_CLIENT_RELAY_SESSION=$url
   export JUMP_CLIENT_LOG_LEVEL=warn
   export JUMP_CLIENT_LOG_FILE=stdout
   export JUMP_CLIENT_LOG_FORMAT=text
   export JUMP_CLIENT_TOKEN=token
   ../bin/jump client & pids+=( "$!" )
done

while true; do

read -p "Do you want to stop the jump clients? (y/n) " yn

case $yn in 
	[yY] ) echo;
		break;;
	[nN] ) echo ok, keeping them going.;;
	* ) echo invalid response;;
esac

done

for pid in "${pids[@]}"
do
	echo killing $pid
	kill $pid
done
