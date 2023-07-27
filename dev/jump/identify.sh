#!/bin/bash
./get-stats.sh| grep $1 | grep -v '/' | sort

