#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Mar 16 13:59:44 2023

@author: tim
"""

# {"audience":"wss://dev.practable.io/relay","booking_id":"relay-token-cli","buffer_size":256,"can_read":true,"can_write":true,"expires_at":1834790887,"level":"info","msg":"new connection","name":"43b16588-ebff-4636-bce3-6fc349266936","remote_addr":"129.215.182.189","stats":true,"time":"2023-03-16T09:09:26Z","topic":"pend24-st-data","user_agent":"Go-http-client/1.1"}

# load all log files
# map all new connection messages
# remove duplicates -> map by booking id, and keep only the earliest connection? Just count every booking taken up as one use for the full duration of that booking, starting from the earliest new-connection.


import glob, json, os

if True:
    connections = []
    
    for file in glob.glob("./relay/*.log"):
        with open(file) as f:

            for line in f:
                data = json.loads(line)
                if "msg" in data:
                    if data["msg"] == "new connection":
                        connections.append(data)
        print("%s: %d\n"%(file, len(connections)))                
           
    with open(r'./relay/new-connections.json', 'w') as file:
        json.dump(connections, file) 

with open(r'./relay/new-connections.json', 'r') as file:
    data = json.load(file)
    
print(len(data))

bid = {}

for c in data:
    if "booking_id" in c:
        if c["booking_id"] != "":
            if not c["booking_id"] in bid:
                bid[c["booking_id"]]=[]
            
            bid[c["booking_id"]].append(c)
            
print(len(bid))

prebooked = {}

for b in bid:
    if len(b) == 9:
        prebooked[b] = bid[b]
        
print(len(prebooked)) 

       
    
