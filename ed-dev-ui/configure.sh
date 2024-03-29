#!/bin/bash

# tidy up any stale files
rm -rf ./autogenerated
rm -rf ./playbooks

#ignore errors when creating dirs, as they might already exist, although we don't check
mkdir -p autogenerated || true 
mkdir -p logs || true 
mkdir -p playbooks || true
mkdir -p relay || true

# Edit to suit your instance

# Directory for services secrets (must contain book.pat, jump.pat, project, relay.pat)
export SECRETS=~/secret/app.practable.io/ed-dev-ui
export EXPT_SECRETS=~/secret
export MAIL_SECRET=~/secret/zoho/mail.yaml

export PROJECT=app-practable-io-alpha

# SSH access
export ZONE=europe-west2-c
export INSTANCE=app-practable-io-alpha-ed-dev-ui

# Health check info
export BACKEND_SERVICE=ci-https-redirect-backend-ed-dev-ui

# Networking info for services & ansible nginx conf
export INSTANCE_PATH=ed-dev-ui
# used in nginx configuration & ansible playbook for lets encrypt
export DOMAIN=app.practable.io
# Used in ansible nginx playbook for setting up certbot
export EMAIL=rl.eng@ed.ac.uk
# used in all ansible playbook templates (note usually underscore, not hyphen)
export ANSIBLE_GROUP=app_practable_ed_dev_ui


# Note that the git-pull-<name>.sh scripts don't check the sub-dirs var because of lack of portability of
# handling arrays in bash - manually update these scripts if change sub-dirs
# Static content for developer: Alonso 
export ALONSO_STATIC_REPO_NAME=static-app-practable-io-ed-dev-ui-alonso
export ALONSO_STATIC_REPO_URL=https://github.com/practable/static-app-practable-io-ed-dev-ui-alonso.git
export ALONSO_STATIC_SUB_DIRS="['config', 'images', 'info', 'ui']"

# Static content for developer: David 
export DAVID_STATIC_REPO_NAME=static-app-practable-io-ed-dev-ui-david
export DAVID_STATIC_REPO_URL=https://github.com/practable/static-app-practable-io-ed-dev-ui-david.git
export DAVID_STATIC_SUB_DIRS="['config', 'images', 'info', 'ui']"

# Static content for developer: Sijie
export SIJIE_STATIC_REPO_NAME=static-app-practable-io-ed-dev-ui-sijie
export SIJIE_STATIC_REPO_URL=https://github.com/practable/static-app-practable-io-ed-dev-ui-sijie.git
export SIJIE_STATIC_SUB_DIRS="['config', 'images', 'info', 'ui']"

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

# create nginx.conf with the ports and routings above
# export vars to avoid $request_uri, $uri etc being replaced with blank
# https://unix.stackexchange.com/questions/294378/replacing-only-specific-variables-with-envsubst
envsubst '${BOOK_PORT} ${DOMAIN} ${HTTPS_HOST} ${INSTANCE_PATH} ${RELAY_PORT_ACCESS} ${RELAY_PORT_RELAY} ${JUMP_PORT_ACCESS} ${JUMP_PORT_RELAY} ${STATUS_PORT_SERVE}' < ./templates/nginx.conf.template > ./autogenerated/nginx.conf

# Create a vars file for ansible, so we can refer to the domain as needed.
envsubst '${DOMAIN}  ${INSTANCE_PATH} ${ALONSO_STATIC_REPO_NAME} ${ALONSO_STATIC_REPO_URL} ${ALONSO_STATIC_SUB_DIRS} ${DAVID_STATIC_REPO_NAME} ${DAVID_STATIC_REPO_URL} ${DAVID_STATIC_SUB_DIRS} ${SIJIE_STATIC_REPO_NAME} ${SIJIE_STATIC_REPO_URL} ${SIJIE_STATIC_SUB_DIRS}' < ./templates/vars.yml.template > ./autogenerated/vars.yml

# Populate our playbooks with group name and other variables
export SSL_DOMAIN="${DOMAIN}/${INSTANCE_PATH}"
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-configure-kernel.yml.template > ./playbooks/configure-kernel.yml
envsubst '${ANSIBLE_GROUP} ${SSL_DOMAIN} ${EMAIL}' < ./templates/playbook-install-nginx.yml.template > ./playbooks/install-nginx.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-update-nginx-conf.yml.template > ./playbooks/update-nginx-conf.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-update-static-contents.yml.template > ./playbooks/update-static-contents.yml

envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-install-webhook.yml.template > ./playbooks/install-webhook.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-update-hooks.yml.template > ./playbooks/update-hooks.yml

# Kernel configuration file
envsubst '${BOOK_AUDIENCE} ${BOOK_SECRET} ${DOMAIN}  ${INSTANCE_PATH}' < ./templates/sysctl-tcp-mem.conf.template > ./autogenerated/tcp-mem.conf

#webhooks config file & scripts
envsubst '' < ./templates/webhook.conf.template > ./autogenerated/webhook.conf

envsubst '${DOMAIN}  ${INSTANCE_PATH} ${ALONSO_STATIC_REPO_NAME} ${ALONSO_STATIC_REPO_URL} ${ALONSO_STATIC_SUB_DIRS}' < ./templates/webhook-git-pull-alonso.sh.template > ./autogenerated/git-pull-alonso.sh

envsubst '${DOMAIN}  ${INSTANCE_PATH} ${DAVID_STATIC_REPO_NAME} ${DAVID_STATIC_REPO_URL} ${DAVID_STATIC_SUB_DIRS}' < ./templates/webhook-git-pull-david.sh.template > ./autogenerated/git-pull-david.sh

envsubst '${DOMAIN}  ${INSTANCE_PATH} ${SIJIE_STATIC_REPO_NAME} ${SIJIE_STATIC_REPO_URL} ${SIJIE_STATIC_SUB_DIRS}' < ./templates/webhook-git-pull-sijie.sh.template > ./autogenerated/git-pull-sijie.sh

envsubst '' < ./templates/webhook.service.template > ./autogenerated/webhook.service

