#!/bin/bash

# Usage ./ansible-login <options> <expt_id> [command]
# Example usage: ansible-login.sh -vvv -C -o ControlMaster=auto -o ControlPersist=60s -o KbdInteractiveAuthentication=no -o PreferredAuthentications=gssapi-with-mic,gssapi-keyex,hostbased,publickey -o PasswordAuthentication=no -o ConnectTimeout=10 -o ControlPath=/home/tim/.ansible/cp/c235afd0de spin30 '/bin/sh -c '"'"'echo ~ && sleep 0'"'"''

# split our arguments into options, expt id, and command
target="^(.*?)( [a-zA-Z0-9]+ )(.*'.*')"
echo "all opts: $*"

[[ "$*" =~ $target ]]

# debug only
#    for i in "${!BASH_REMATCH[@]}"; do
#        echo "$i: ${BASH_REMATCH[$i]}"
#    done

OPTIONS="${BASH_REMATCH[1]}"
EXPT="${BASH_REMATCH[2]}"
COMMAND="${BASH_REMATCH[3]}"

#for debug only - upsets ansible if echo unexpected things
#echo "options: $OPTIONS"
#echo "expt: $EXPT"
#echo "command: $COMMAND"

function freeport(){
 #https://unix.stackexchange.com/questions/55913/whats-the-easiest-way-to-find-an-unused-local-port
 port=$(comm -23 <(seq 49152 65535 | sort) <(ss -Htan | awk '{print $4}' | cut -d':' -f2 | sort -u) | sort -n | head -n 1)
}

freeport

export JUMP_TOKEN_AUDIENCE=https://app.practable.io/ed0/jump
export JUMP_TOKEN_CONNECTION_TYPE=connect
export JUMP_TOKEN_LIFETIME=86400
export JUMP_TOKEN_ROLE=client
export JUMP_TOKEN_SECRET=$(</home/tim/secret/app.practable.io/ed0/jump.pat)
export JUMP_TOKEN_TOPIC=$EXPT

export JUMP_BASE_PATH=/api/v1 
export JUMP_CLIENT_LOCAL_PORT="${port}"
export JUMP_CLIENT_RELAY_SESSION="${JUMP_TOKEN_AUDIENCE}${JUMP_BASE_PATH}/${JUMP_TOKEN_CONNECTION_TYPE}/${JUMP_TOKEN_TOPIC}"
export JUMP_CLIENT_TOKEN=$(../bin/jump token)
export JUMP_CLIENT_LOG_LEVEL=error
export JUMP_CLIENT_LOG_FILE=stdout
export JUMP_CLIENT_LOG_FORMAT=text
../bin/jump client >/dev/null 2>&1 &
pid=$!
export SSHPASS=$(/home/tim/secret/ep $EXPT)
user=$(/home/tim/secret/eu $EXPT)
#sshpass -v -e ssh -o "StrictHostKeyChecking no" "${user}@localhost" -p "$port"
#sshpass -v -e ssh -C -o ControlMaster=auto -o ControlPersist=60s -o KbdInteractiveAuthentication=no -o PreferredAuthentications=gssapi-with-mic,gssapi-keyex,hostbased,publickey -o PasswordAuthentication=no -o ConnectTimeout=10 -o ControlPath=/home/tim/.ansible/cp/c235afd0de "${user}@localhost" -p "$port" '/bin/sh -c '"'"'echo ~ && sleep 0'"'"''

sshpass -v -e ssh $OPTIONS "${user}@localhost" -p "$port" $COMMAND

kill $!



