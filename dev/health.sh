#/bin/bash
#https://stackoverflow.com/questions/65610480/gcloud-compute-backend-services-provides-a-not-found-error
gcloud compute backend-services get-health ci-https-redirect-backend-dev --project "app-practable-io-alpha" --global
