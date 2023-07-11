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


connections = {}


import os

directory = os.fsencode("./data/") 
for file in os.listdir(directory):
     filename = os.fsdecode(file)
     if filename.endswith(".log"): 
         print(os.path.join(directory, filename))
         continue
     else:
         continue