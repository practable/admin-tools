#!/bin/bash

# https://gist.github.com/angelo-v/e0208a18d455e2e6ea3c40ad637aac53
# pad base64URL encoded to base64
paddit() {
  input=$1
  l=`echo -n $input | wc -c`
  while [ `expr $l % 4` -ne 0 ]
  do
    input="${input}="
    l=`echo -n $input | wc -c`
  done
  echo $input
}

decodejwt() {
# read and split the token and do some base64URL translation
read h p s <<< $(echo $1 | tr [-_] [+/] | sed 's/\./ /g')

h=`paddit $h`
p=`paddit $p`

# assuming we have jq installed
echo $h | base64 -d | jq
echo $p | base64 -d | jq

exp=$(echo $p | base64 -d | jq '.exp')
expdate=$(date -d "@${exp}")

iat=$(echo $p | base64 -d | jq '.iat')
iatdate=$(date -d "@${iat}")

nbf=$(echo $p | base64 -d | jq '.nbf')
nbfdate=$(date -d "@${nbf}")

echo "exp: ${expdate}"
echo "iat: ${iatdate}"
echo "nbf: ${nbfdate}"
}


# Make token
export RELAY_TOKEN_LIFETIME=30
export RELAY_TOKEN_SCOPE_READ=true
export RELAY_TOKEN_SCOPE_WRITE=false
export RELAY_TOKEN_SECRET=$(cat ~/secret/v0/relay.pat)
export RELAY_TOKEN_TOPIC=stats
export RELAY_TOKEN_AUDIENCE=https://dev.practable.io/access
export client_token=$(../bin/relay token)
echo "client token:"
echo ${client_token}
echo ""
echo "decoded:"
decodejwt $client_token

# Request Access
export ACCESS_URL="${RELAY_TOKEN_AUDIENCE}/session/stats"
echo ""
echo "access to ${ACCESS_URL}:"
echo ""
export RESP=$(curl -s -X POST \
-H "Authorization: ${client_token}" \
				   $ACCESS_URL)
echo $RESP
echo ""
