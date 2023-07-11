#!/bin/bash
EXPT=$1
export RELAY_TOKEN_LIFETIME=157680000
export RELAY_TOKEN_READ=true
export RELAY_TOKEN_WRITE=true
export RELAY_TOKEN_SECRET=$(cat ~/secret/v0/relay.pat)
export RELAY_TOKEN_TOPIC=$EXPT
export RELAY_TOKEN_AUDIENCE=https://dev.practable.io/access
../bin/relay token

