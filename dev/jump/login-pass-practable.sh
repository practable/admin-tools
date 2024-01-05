#!/bin/bash

# Usage ./login <expt_id>
# Example ./login pend00
export EXPT=$1

function freeport(){
 #https://unix.stackexchange.com/questions/55913/whats-the-easiest-way-to-find-an-unused-local-port
 port=$(comm -23 <(seq 49152 65535 | sort) <(ss -Htan | awk '{print $4}' | cut -d':' -f2 | sort -u) | sort -n | head -n 1)
}

freeport

export JUMP_TOKEN_AUDIENCE=https://app.practable.io/dev/jump
export JUMP_TOKEN_CONNECTION_TYPE=connect
export JUMP_TOKEN_LIFETIME=86400
export JUMP_TOKEN_ROLE=client
export JUMP_TOKEN_SECRET=$(</home/tim/secret/app.practable.io/dev/jump.pat)
export JUMP_TOKEN_TOPIC=$EXPT

export JUMP_BASE_PATH=/api/v1 
export JUMP_CLIENT_LOCAL_PORT="${port}"
export JUMP_CLIENT_RELAY_SESSION="${JUMP_TOKEN_AUDIENCE}${JUMP_BASE_PATH}/${JUMP_TOKEN_CONNECTION_TYPE}/${JUMP_TOKEN_TOPIC}"
export JUMP_CLIENT_TOKEN=$(../bin/jump token)
export JUMP_CLIENT_LOG_LEVEL=trace
export JUMP_CLIENT_LOG_FILE=stdout
export JUMP_CLIENT_LOG_FORMAT=text
../bin/jump client >/dev/null 2>&1 &
pid=$!
sleep 1 #delay for port to be open
echo ssh -o "StrictHostKeyChecking no" -i ~/secret/practable-experiments practable@localhost -p "$port"
ssh -o "StrictHostKeyChecking no" -i ~/secret/practable-experiments practable@localhost -p "$port"
kill $!



