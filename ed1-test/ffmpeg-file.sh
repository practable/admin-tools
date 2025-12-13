#!/bin/sh
# re sets real-time framerate
ffmpeg -re -i /home/tim/video.ts -f mpegts -codec:v mpeg1video http://localhost:8888/ts/video
