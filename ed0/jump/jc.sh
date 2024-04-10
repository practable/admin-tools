#!/bin/bash

# Usage ./jc <expt_id> <port>
# Example ./jc pend00 10200
export EXPT=$1
export port=$2

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
pass=$(/home/tim/secret/ep $EXPT)
user=$(/home/tim/secret/eu $EXPT)
#echo "login with password $pass using"
#echo "ssh ${user}@localhost -p $port"
../bin/jump client  >/dev/null 2>&1 &
pid=$!
echo $pid





