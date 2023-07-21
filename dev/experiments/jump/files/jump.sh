#!/bin/bash
systemctl stop jump.service
cd sources
rm -rf jump
wget https://golang.org/dl/go1.20.1.linux-armv6l.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.20.1.linux-armv6l.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
source /etc/profile
git clone https://github.com/practable/jump.git
cd jump/scripts/build
./build.sh
cd ../../cmd/jump
cp jump /usr/local/bin
cd ../../../
export SECRET_FILES=$(cat /tmp/files.link)
wget $SECRET_FILES/getid.sh -O getid.sh
chmod +x ./getid.sh
./getid.sh
export PRACTABLE_ID=$(./getid.sh)
cd /etc/practable
wget $SECRET_FILES/jump.env.$PRACTABLE_ID -O jump.env
cd /etc/systemd/system
wget $SECRET_FILES/jump.service -O jump.service
systemctl enable jump.service
systemctl start jump.service
