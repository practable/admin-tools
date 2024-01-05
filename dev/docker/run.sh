#!/bin/bash
docker rm virtual-experiments
docker run --name virtual-experiments -d virtual-experiments:v0

