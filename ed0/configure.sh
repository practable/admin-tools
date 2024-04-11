#!/bin/bash

# tidy up any stale files
rm -rf ./autogenerated
rm -rf ./playbooks

#ignore errors when creating dirs, as they might already exist, although we don't check
mkdir -p autogenerated || true 
mkdir -p book || true
mkdir -p experiments/files || true
mkdir -p jump || true
mkdir -p logs || true 
mkdir -p playbooks || true
mkdir -p relay || true

# Edit to suit your instance

# Directory for services secrets (must contain book.pat, jump.pat, project, relay.pat)
export SECRETS=~/secret/app.practable.io/ed0
export EXPT_SECRETS=~/secret
export MAIL_SECRET=~/secret/zoho/mail.yaml

export PROJECT=app-practable-io-alpha

# SSH access
export ZONE=europe-west2-c
export INSTANCE=app-practable-io-alpha-ed0

# Health check info
export BACKEND_SERVICE=ci-https-redirect-backend-ed0

# Networking info for services & ansible nginx conf
export INSTANCE_PATH=ed0
# used in nginx configuration & ansible playbook for lets encrypt
export DOMAIN=app.practable.io
# Used in ansible nginx playbook for setting up certbot
export EMAIL=rl.eng@ed.ac.uk
# used in all ansible playbook templates (note usually underscore, not hyphen)
export ANSIBLE_GROUP=app_practable_ed0

# Static content: main/default content for the instance ("production" equivalent)
export STATIC_REPO_NAME=static-app-practable-io-ed0-default
export STATIC_REPO_URL=https://github.com/practable/static-app-practable-io-ed0-default.git
# Note that book is deliberately not included in this list of sub-dirs
export STATIC_SUB_DIRS="['config', 'images', 'info', 'ui']"

# Static content: development versions on same server (TODO improve to let devs be self sufficient)
export DEV_STATIC_REPO_NAME=static-app-practable-io-ed0-dev
export DEV_STATIC_REPO_URL=https://github.com/practable/static-app-practable-io-ed0-dev.git
# Note that book is deliberately not included in this list of sub-dirs
export DEV_STATIC_SUB_DIRS="['config', 'images', 'info', 'ui']"

# Experiment setup & migration helpers (optional, but must be defined for script to run)
export STREAM_STUB=st-ed0-
# migration helper files, such as env, access, and token files
# these should be placed in an unguessable location
# (e.g. in folder named with a uuid)
# on a server that does NOT allow indexing
# and removed after the migration is finished
export MIGRATE_FILES=$(cat ${SECRETS}/files.link)
# existing access file on experiment 
export OLD_ACCESS_FILE=data.access
# regexp to extract the id from the old access file
export OLD_ID_FILTER='https://relay-access.practable.io/session/(\w*)-data'
# use arm64 for odroid, armv6l for rpi
export EXPERIMENT_LINUX=go1.20.1.linux-armv6l.tar.gz

# Virtual experiments (optional, but must be defined for script to run)
export VE_NUM=3
export VE_LIFETIME=604800
export JUMP_BASE_PATH=/api/v1
export BOOK_BASE_PATH=/api/v1
	
###########################################################################
# Do not edit below this line (unless you want a non-standard installation)
###########################################################################

# Do NOT pass and actual secret to a template - instead pass an eval command on a path e.g. `$(cat ${SECRETS}/some_secret.pat)`
# this is to avoid leaking secrets into the git repo if autogenerated files are added inadvertently
# which is possible given that they are deployed into directories for convenience.

export HTTPS_HOST="https://${DOMAIN}/${INSTANCE_PATH}"
export WSS_HOST="wss://${DOMAIN}/${INSTANCE_PATH}"

# create login.sh
envsubst '${INSTANCE} ${PROJECT} ${ZONE}' < ./templates/login.sh.template > ./login.sh
chmod +x ./login.sh

#create health.sh
envsubst '${BACKEND_SERVICE} ${PROJECT}' < ./templates/health.sh.template > ./health.sh
chmod +x ./health.sh

# Create book.service by adding variables to template
export BOOK_PORT=4000
export BOOK_AUDIENCE="${HTTPS_HOST}/book"
export BOOK_SECRET=$(cat ${SECRETS}/book.pat)
export RELAY_SECRET=$(cat  ${SECRETS}/relay.pat)
envsubst < ./templates/book.service.template > ./autogenerated/book.service

# create relay.service by adding variables to template
export RELAY_ALLOW_NO_BOOKING_ID=true
export RELAY_AUDIENCE="${HTTPS_HOST}/access"
export RELAY_PORT_ACCESS=3000
export RELAY_PORT_PROFILE=6061
export RELAY_PORT_RELAY=3001
export RELAY_SECRET=$(cat ${SECRETS}/relay.pat)
export RELAY_URL="${WSS_HOST}/relay"
envsubst < ./templates/relay.service.template > ./autogenerated/relay.service

# create jump.service by adding variables to template
export JUMP_AUDIENCE="${HTTPS_HOST}/jump"
export JUMP_PORT_ACCESS=3002
export JUMP_PORT_RELAY=3003
export JUMP_SECRET=$(cat ${SECRETS}/jump.pat)
export JUMP_URL="${WSS_HOST}/jump"
envsubst < ./templates/jump.service.template > ./autogenerated/jump.service

#create status.service by adding variables to template
export STATUS_EMAIL_FROM=$(yq -r '.username' $MAIL_SECRET)
export STATUS_EMAIL_HOST=$(yq -r '.host' $MAIL_SECRET)
export STATUS_EMAIL_LINK=$HTTPS_HOST/status
export STATUS_EMAIL_PASSWORD=$(yq -r '.password' $MAIL_SECRET)
export STATUS_EMAIL_PORT=$(yq -r '.port' $MAIL_SECRET)
export STATUS_EMAIL_SUBJECT=$DOMAIN/$INSTANCE_PATH
export STATUS_EMAIL_TO=$(yq -r '.to' $MAIL_SECRET)
export STATUS_PORT_SERVE=3007
envsubst < ./templates/status.service.template > ./autogenerated/status.service

# create nginx.conf with the ports and routings above
# export vars to avoid $request_uri, $uri etc being replaced with blank
# https://unix.stackexchange.com/questions/294378/replacing-only-specific-variables-with-envsubst
envsubst '${BOOK_PORT} ${DOMAIN} ${HTTPS_HOST} ${INSTANCE_PATH} ${RELAY_PORT_ACCESS} ${RELAY_PORT_RELAY} ${JUMP_PORT_ACCESS} ${JUMP_PORT_RELAY} ${STATUS_PORT_SERVE}' < ./templates/nginx.conf.template > ./autogenerated/nginx.conf

# Create a vars file for ansible, so we can refer to the domain as needed.
envsubst '${DOMAIN}  ${INSTANCE_PATH} ${STATIC_REPO_NAME} ${STATIC_REPO_URL} ${STATIC_SUB_DIRS} ${DEV_STATIC_REPO_NAME} ${DEV_STATIC_REPO_URL} ${DEV_STATIC_SUB_DIRS}' < ./templates/vars.yml.template > ./autogenerated/vars.yml

# Populate our playbooks with group name and other variables
export SSL_DOMAIN="${DOMAIN}/${INSTANCE_PATH}"
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-download-logs.yml.template > ./playbooks/download-logs.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-configure-kernel.yml.template > ./playbooks/configure-kernel.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-install-book.yml.template > ./playbooks/install-book.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-install-jump.yml.template > ./playbooks/install-jump.yml
envsubst '${ANSIBLE_GROUP} ${SSL_DOMAIN} ${EMAIL}' < ./templates/playbook-install-nginx.yml.template > ./playbooks/install-nginx.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-install-relay.yml.template > ./playbooks/install-relay.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-install-status.yml.template > ./playbooks/install-status.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-revert-relay.yml.template > ./playbooks/revert-relay.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-update-book.yml.template > ./playbooks/update-book.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-update-book-service.yml.template > ./playbooks/update-book-service.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-update-jump.yml.template > ./playbooks/update-jump.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-update-jump-service.yml.template > ./playbooks/update-jump-service.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-update-nginx-conf.yml.template > ./playbooks/update-nginx-conf.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-update-relay.yml.template > ./playbooks/update-relay.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-update-relay-service.yml.template > ./playbooks/update-relay-service.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-update-status.yml.template > ./playbooks/update-status.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-update-status-service.yml.template > ./playbooks/update-status-service.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-update-static-contents.yml.template > ./playbooks/update-static-contents.yml

# Kernel configuration file
envsubst '${BOOK_AUDIENCE} ${BOOK_SECRET} ${DOMAIN}  ${INSTANCE_PATH}' < ./templates/sysctl-tcp-mem.conf.template > ./autogenerated/tcp-mem.conf

# Administration scripts
envsubst '${BOOK_AUDIENCE} ${BOOK_SECRET} ${DOMAIN}  ${INSTANCE_PATH}' < ./templates/book-admin.template > ./book/admin.sh
chmod +x ./book/admin.sh

envsubst '${BOOK_AUDIENCE}' < ./templates/book-generate-bookings.sh.template > ./book/generate-bookings.sh
chmod +x ./book/generate-bookings.sh

envsubst '' < ./templates/book-check-exported-bookings.sh.template > ./book/check-exported-bookings.sh
chmod +x ./book/check-exported-bookings.sh

envsubst '' < ./templates/book-compare-bookings.sh.template > ./book/compare-bookings.sh
chmod +x ./book/compare-bookings.sh

envsubst '' < ./templates/book-merge-bookings.sh.template > ./book/merge-bookings.sh
chmod +x ./book/merge-bookings.sh

envsubst '' < ./templates/book-show-counts.sh.template > ./book/show-counts.sh
chmod +x ./book/show-counts.sh

envsubst '' < ./templates/book-show-current-bookings.sh.template > ./book/show-current-bookings.sh
chmod +x ./book/show-current-bookings.sh

envsubst '${HTTPS_HOST}  ${SECRETS}' < ./templates/jump-get-stats.sh.template > ./jump/get-stats.sh
chmod +x ./jump/get-stats.sh

envsubst '${HTTPS_HOST}  ${SECRETS}' < ./templates/jump-check-access.sh.template > ./jump/check-access.sh
chmod +x ./jump/check-access.sh

envsubst '${HTTPS_HOST}  ${SECRETS} ${EXPT_SECRETS}' < ./templates/jump-login.sh.template > ./jump/login.sh
chmod +x ./jump/login.sh

envsubst '${HTTPS_HOST}  ${SECRETS} ${EXPT_SECRETS}' < ./templates/jump-scpr2l.sh.template > ./jump/scpr2l.sh
chmod +x ./jump/scpr2l.sh

envsubst '${HTTPS_HOST}  ${SECRETS} ${EXPT_SECRETS}' < ./templates/jump-scpl2r.sh.template > ./jump/scpl2r.sh
chmod +x ./jump/scpl2r.sh

envsubst '' < ./templates/jump-identify.sh.template > ./jump/identify.sh
chmod +x ./jump/identify.sh


envsubst '${HTTPS_HOST}  ${SECRETS}' < ./templates/relay-get-stats.sh.template > ./relay/get-stats.sh
chmod +x ./relay/get-stats.sh

envsubst '${HTTPS_HOST}  ${SECRETS}' < ./templates/relay-identify.sh.template > ./relay/identify.sh
chmod +x ./relay/identify.sh

# Experiments

envsubst '${RELAY_AUDIENCE} ${RELAY_SECRET} ${JUMP_AUDIENCE} ${JUMP_SECRET} ${STREAM_STUB}' < ./templates/experiments-configure.template > ./experiments/configure
chmod +x ./experiments/configure

envsubst '' < ./templates/experiments-jci.sh.template > ./experiments/jci.sh
chmod +x ./experiments/jci.sh

envsubst '${SECRETS} ${EXPT_SECRETS}' < ./templates/experiments-jc.sh.template > ./experiments/jc.sh
chmod +x ./experiments/jc.sh

envsubst '${EXPT_SECRETS}' < ./templates/experiments-locdn.sh.template > ./experiments/locdn.sh
chmod +x ./experiments/locdn.sh

envsubst '' < ./templates/experiments-jcikill.sh.template > ./experiments/jcikill.sh
chmod +x ./experiments/jcikill.sh

envsubst '' < ./templates/experiments-jump-playbook.template > ./experiments/jump-playbook
chmod +x ./experiments/jump-playbook

envsubst '' < ./templates/ansible.cfg.template > ./experiments/ansible.cfg #needed in dir that playbooks are in
envsubst '' < ./templates/experiments-helloworld.yml.template > ./experiments/helloworld.yml
envsubst '' < ./templates/experiments-shutdown.yml.template > ./experiments/shutdown.yml



# no substitutions in these four, at this time
envsubst '' < ./templates/experiments-relayaccess.template > ./experiments/relayaccess
chmod +x ./experiments/relayaccess

envsubst '${STREAM_STUB}' < ./templates/experiments-relaytoken.template > ./experiments/relaytoken
chmod +x ./experiments/relaytoken

# jump

envsubst '' < ./templates/experiments-jumphost.template > ./experiments/jumphost
chmod +x ./experiments/jumphost

envsubst '' < ./templates/experiments-jumpclient.template > ./experiments/jumpclient
chmod +x ./experiments/jumpclient

envsubst '' < ./templates/experiments-jump.service.template > ./experiments/jump.service



# Migration scripts
envsubst '${MIGRATE_FILES} ${OLD_ACCESS_FILE} ${OLD_ID_FILTER}' < ./templates/migrate-getid.sh.template > ./experiments/files/getid.sh
envsubst '${MIGRATE_FILES} ${EXPERIMENT_LINUX}' < ./templates/migrate-jump.sh.template > ./experiments/files/jump.sh
envsubst '${MIGRATE_FILES} ${STREAM_STUB}' < ./templates/migrate-relay.sh.template > ./experiments/files/relay.sh
envsubst '${STREAM_STUB}' < ./templates/migrate-session-rules.template > ./experiments/files/session-rules
envsubst '' < ./templates/migrate-jump.service.template > ./experiments/files/jump.service
envsubst '' < ./templates/migrate-websocat-data.template > ./experiments/files/websocat-data
chmod +x ./experiments/files/session-rules
chmod +x ./experiments/files/websocat-data
envsubst '${MIGRATE_FILES}' < ./templates/migrate-install.sh.template > ./experiments/files/install.sh
chmod +x ./experiments/files/install.sh
# Virtual experiments

# make tokens and access files for jump; relay
# these have to go inside the docker build context, hence putting in ./docker
rm -rf ./docker/autogenerated/virtual-experiments 
mkdir -p ./docker/autogenerated/virtual-experiments

for i in $(seq 0 $VE_NUM)
do
	num=$(printf "%02d" $i)
    expt="test${num}"
	# Jump token
	export JUMP_TOKEN_LIFETIME=$VE_LIFETIME
	export JUMP_TOKEN_ROLE=host
	export JUMP_TOKEN_SECRET=$JUMP_SECRET
	export JUMP_TOKEN_TOPIC=$expt
	export JUMP_TOKEN_CONNECTION_TYPE=connect
	export JUMP_TOKEN_AUDIENCE=$JUMP_AUDIENCE
	./bin/jump token > "./docker/autogenerated/virtual-experiments/jump-${JUMP_TOKEN_TOPIC}.token"

	# Jump access
	export  JUMP_HOST_ACCESS=${JUMP_AUDIENCE}${JUMP_BASE_PATH}/${JUMP_TOKEN_CONNECTION_TYPE}/${JUMP_TOKEN_TOPIC}
	echo $JUMP_HOST_ACCESS > "./docker/autogenerated/virtual-experiments/jump-${JUMP_TOKEN_TOPIC}.access"

	# Relay Token (data)
	
	export RELAY_TOKEN_LIFETIME=$VE_LIFETIME
	export RELAY_TOKEN_SCOPE_OTHER=expt
	export RELAY_TOKEN_SCOPE_READ=true
	export RELAY_TOKEN_SCOPE_WRITE=true
	export RELAY_TOKEN_SECRET=$RELAY_SECRET
	export RELAY_TOKEN_TOPIC="${expt}-st-data"
	export RELAY_TOKEN_AUDIENCE=$RELAY_AUDIENCE
	./bin/relay token > "./docker/autogenerated/virtual-experiments/relay-${RELAY_TOKEN_TOPIC}.token"

	# Relay access (data)
	export RELAY_ACCESS=${RELAY_TOKEN_AUDIENCE}/session/${RELAY_TOKEN_TOPIC}
	echo $RELAY_ACCESS > "./docker/autogenerated/virtual-experiments/relay-${RELAY_TOKEN_TOPIC}.access"

	
	# Relay token (video)
	export RELAY_TOKEN_LIFETIME=$VE_LIFETIME
	export RELAY_TOKEN_SCOPE_OTHER=expt
	export RELAY_TOKEN_SCOPE_READ=true
	export RELAY_TOKEN_SCOPE_WRITE=true
	export RELAY_TOKEN_SECRET=$RELAY_SECRET
	export RELAY_TOKEN_TOPIC="${expt}-st-video"
	export RELAY_TOKEN_AUDIENCE=$RELAY_AUDIENCE
	./bin/relay token > "./docker/autogenerated/virtual-experiments/relay-${RELAY_TOKEN_TOPIC}.token"
	
	# Relay access (video)
	export RELAY_ACCESS=${RELAY_TOKEN_AUDIENCE}/session/${RELAY_TOKEN_TOPIC}
	echo $RELAY_ACCESS > "./docker/autogenerated/virtual-experiments/relay-${RELAY_TOKEN_TOPIC}.access"

done

# make the session-rules script
envsubst '${VE_NUM}' < ./templates/relay-rules.sh.template > ./docker/autogenerated/relay-rules.sh
chmod +x ./docker/autogenerated/relay-rules.sh

# configure the run.sh script for the docker container
envsubst '${VE_NUM} ${VE_LIFETIME}' < ./templates/virtual-experiments.sh.template > ./docker/autogenerated/virtual-experiments.sh
chmod +x ./docker/autogenerated/virtual-experiments.sh


# Make the booking manifest (demo version)
envsubst '${RELAY_AUDIENCE}' < ./templates/book-manifest.yaml.template > ./book/manifest.yaml

# booking scripts
envsubst '${SECRETS} ${BOOK_AUDIENCE} ${DOMAIN} ${INSTANCE_PATH} ${BOOK_BASE_PATH}' < ./templates/book-upload.sh.template > ./book/upload.sh
chmod +x ./book/upload.sh



