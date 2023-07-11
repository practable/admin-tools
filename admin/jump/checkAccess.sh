#!/bin/sh

# Make token
export JUMP_TOKEN_AUDIENCE=https://dev.practable.io/jump
export JUMP_TOKEN_CONNECTION_TYPE=connect
export JUMP_TOKEN_LIFETIME=30
export JUMP_TOKEN_ROLE=stats
export JUMP_TOKEN_SECRET=$(<~/secret/v0/jump.pat)
export JUMP_TOKEN_TOPIC=stats
export TOKEN=$(../bin/jump token)
echo $TOKEN | decode-jwt
export JUMP_BASE_PATH=/api/v1 
# Request Access
export ACCESS_URL="${JUMP_TOKEN_AUDIENCE}${JUMP_BASE_PATH}/${JUMP_TOKEN_CONNECTION_TYPE}/${JUMP_TOKEN_TOPIC}"
echo $ACCESS_URL
curl -X POST  \
-H "Authorization: ${TOKEN}" \
$ACCESS_URL 

