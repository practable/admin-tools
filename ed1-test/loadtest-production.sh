#!/bin/bash
# example usage ./loadtest.sh 199 #will run 0-199 feeds

declare -i id
declare -a code=("pend" "spin" "dyna" "trus" "tors")
declare -a first=(1 33 0 0 0)
declare -a last=(44 77 17 7 4)

# get length of an array
arraylength=${#code[@]}

# use for loop to read all values and indexes
for (( i=0; i<${arraylength}; i++ ));
do
  #echo "index: $i, code: ${code[$i]}, first: ${first[$i]}, last: ${last[$i]}"
  for j in $(seq ${first[$i]} ${last[$i]})
  do
        num=$(printf "%02d" $j)
        name="${code[$i]}${num}"
        videoAccess=$(cat video.access.$name)
        videoToken=$(cat video.token.$name)
        curl -X POST -H "Content-Type: application/json" -d '{"stream":"video","destination":"'"${videoAccess}"'","id":"'"$((++id))"'","token":"'"${videoToken}"'"}' http://localhost:8888/api/destinations
        dataAccess=$(cat data.access.$name)
        dataToken=$(cat data.token.$name)
        curl -X POST -H "Content-Type: application/json" -d '{"stream":"data","destination":"'"${dataAccess}"'","id":"'"$((++id))"'","token":"'"${dataToken}"'"}' http://localhost:8888/api/destinations
  done
done

echo "Started $id feeds"