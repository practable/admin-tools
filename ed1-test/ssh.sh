#/bin/bash
gcloud compute scp --zone "europe-west2-a" --project "test-practable-io-alpha" $1 test-practable-io-alpha-ed1:~
