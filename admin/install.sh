#!/bin/bash
sshpass=$(which sshpass)
if [ ! $? -eq 0 ]; then
   echo "please install sshpass then try again"
fi

go=$(which go)
if [ ! $? -eq 0 ]; then
   echo "please install go then try again"
fi

mkdir .source 2> /dev/null || true
mkdir bin 2> /dev/null || true
cd .source
if cd relay 2> /dev/null; then git pull origin develop; else git clone --branch develop https://github.com/practable/relay && cd relay; fi
cd scripts/build
./build.sh
cp ../../cmd/relay/relay ../../../../bin/relay

cd ../../..
if cd book 2> /dev/null; then git pull origin main; else git clone https://github.com/practable/book && cd book; fi
cd scripts
./build.sh
cp ../cmd/book/book ../../../bin/book

cd ../..
if cd jump 2> /dev/null; then git pull origin main; else git clone https://github.com/practable/jump && cd jump; fi
cd scripts/build
./build.sh
cp ../../cmd/jump/jump ../../../../bin/jump
