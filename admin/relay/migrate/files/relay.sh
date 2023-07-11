#!/bin/bash
# to use this file: wget https://assets.practable.io/84aa5631-7337-433e-bbf9-94f5feb26f0d/relay.sh -O relay.sh; chmod +x relay.sh
# sudo su
# ./relay.sh
export FILES=https://assets.practable.io/84aa5631-7337-433e-bbf9-94f5feb26f0d/
wget $FILES/getid.sh -O getid.sh
chmod +x ./getid.sh
export PRACTABLE_ID=$(./getid.sh)
cd /etc/practable
wget $FILES/st-data.access.$PRACTABLE_ID -O st-data.access
wget $FILES/st-video.access.$PRACTABLE_ID -O st-video.access
wget $FILES/st-data.token.$PRACTABLE_ID -O st-data.token
wget $FILES/st-video.token.$PRACTABLE_ID -O st-video.token
cd /usr/local/bin
wget $FILES/session-rules -O session-rules
chmod +x ./session-rules
systemctl restart session-rules
