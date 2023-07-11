#!/bin/bash
gcloud compute scp --zone "europe-west2-c" --project "healthy-reason-375613" instance-1:/var/log/relay/relay.log ./

