#!/bin/bash
./getShellStats2.sh| grep $1 | grep -v '/' | sort

