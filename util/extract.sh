#!/bin/bash
# print a list of mac addresses associated with expt id that are in one file (all.txt) but not in another (ok.txt)

# format of all.txt and ok.txt issomething like this:
# pend00
# pend01
# etc 

# print every key in the file using yq
cat ~/secret/experiments.yaml | yq 'keys[]' > all.txt
# for every key in all.txt, that is NOT in ok.txt, extract the corresponding mac value from experiments.yaml and save it to a file named affected.txt
# if you've already run the script, delete affected.txt before re-running
while read key; do
  if grep "$key" ok.txt; then
    continue
  fi
  echo "$key : $(~/secret/em $key)" >> affected.txt
done < all.txt
