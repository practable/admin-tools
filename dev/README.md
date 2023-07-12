# app.practable.io/dev


The installation process has several steps

-  gather / generate required information 
   -  ansible inventory "group" name: e.g. app-practable-dev
   -  FQDN of the instance: app.practable.io/dev
   -  generate two UUID to use as secrets for `book+relay`, and `jump` services (hint: use `uuidgen` command)
   -  generate a static files repo for this instance (can populate with user interfaces later)
   -  generate a booking manifest (can do later)
-  customise the configuration 
   -  edit the configuration script using the above information
   -  run the script to produce custom installation files
-  install the services
   -  run a series of ansible playbooks (in a pre-defined order)
-  administration tasks
    -  (re)configure your experiments to point at this instance
    -  upload your booking manifest
    -  check system is working 
    -  share booking links with users
   
   -  
b/ generate secrets for the services
c/ prepare a static files repo for use with the instance (must be customised with correct base path in user interfaces)
d/ edit configuration script
e/ produce customised service files for installation using configuration script
f/ run ansible playbooks to install services 
g/ populate services with data (such as experiment manifest)
h/ (re)configure your experiments to connect to the instance



### Adding a new user interface based on vue.js

-> compile with the instance base path
-> add to static repo
-> edit ./templates/nginx.conf.template to add support the vue router to the static server block, typically of the form

```
        location /static/info/spinner-2.0/ {
            try_files $uri $uri/ $uri.html /info/spinner-2.0/;
            index index.html;
        }
```		

### Adding some other asset to static

-> check in configuration.sh that you have included any new top-level directory in the list of directories 
```
export STATIC_SUB_DIRS="['config', 'images', 'info', 'ui']"
```


# gce-develop
Documentation, files and scripts for setting up the system on gce

## Architecture

book, bookjs, static, and relay on one server for 
- reducing number of instances to manage / certificates to update, by using single subdomain
- separate the jump server so experiments can be managed even if they swamping the main relay with bogus data

The split into static and assets felt more arbitrary in practice than it did at design time, so it proposed to combine assets into the static server with top level directories for each class of static or asset
```
config
images
info
ui
```

We have routings `static` and `dev-static`, so if we are using a git repo we can have the develop branch hosted at dev-static and the main branch hosted at static?

Except ..... any assets referred to will need to change names .... so we should have separate repos... and just pull the main branch of each.

Then we can put assets we need straight into static, but ui can go into dev-static ...

or do we just have a single repo ??

Yes ... a UI can have multiple versions, without needing them to be in a dev-folder, so long as whoever approves the git PR checks for sanity .... mmmmm......

Ah .... what if we have a ui sub-dirs for each developer in the top level of the directory?

```
ui-dpr
ui-tdd
ui-abc
```

Then we could clone the repo to some other location, then symlink from each dir in /var/www/$DOMAIN/ to the appropriate directory

DOr do we keep it simple for now, one repo for static, another repo for dev-static. Dev-static could be a fork of static, so that developers fork dev-static, and then merge their changes back to it. Then admin can merge changes from dev-static back to static.
If someone has merged a change that is broken, while another developer needs to push something from static to main ... what do we do? fork static, drop in the changes, and merge that back directly? Do we drop the idea that dev-static and static are direct mirrors? 

Separate repos for each dev is simpler to manage, and will avoid frustration if one makes changes that mess up another ... but how to manage assets/changes?

## Project

In console:

Set up new project named `docker-dev-practable.io`

Enable Compute Engine API

Create a VM
- europe-west-2, europe-west2-c
- e2-highcpu-4
- Boot image Ubuntu 20.04 LTS x86/64 focal image built 2023-01-13 
- Volume 10GB Balanced disk (best price per GB) Can [increase disk size at any time](https://cloud.google.com/compute/docs/disks/resize-persistent-disk)
- Reserve a static IP address (non shared), let GCE assign the address, that then becomes a primary internal IP (not intended, meant to do external!)
- Set an external static ipv4 address `dev-practable-io-external` 34.105.220.20 (update A-record in Advanced DNS at registrar)
- Enable delete protection
- migrate instance, and auto-restart enabled
- do nothing if CMEK is revoked 


Consider creating ansible tasks for
- installing and running services
  - book
  - relay
  - jump
  - static
  
- updating the nginx configuration
- sorting the ssl certs (cert bot needs to be done manually anyone then is automatic??)

To ssh into the application:
```
gcloud compute ssh --zone "europe-west2-c" "instance-1"  --project "healthy-reason-375613"
```


Ansible support is [described here](https://docs.ansible.com/ansible/latest/scenario_guides/guide_gce.html)

```
$ pip install requests google-auth
```

As per [doc]((https://docs.ansible.com/ansible/latest/scenario_guides/guide_gce.html) In GCP console, Select the project, service account, then go the keys tab and download a JSON key

Then add to `/etc/ansible/ansible.cfg` the following (must include all the default plugins to still be able to parse the standard hosts file)

```
[inventory]
enable_plugins = gcp_compute, host_list, script, auto, yaml, ini, toml 
```

Then create dev.gcp.yml

```
plugin: gcp_compute
projects:
  - xxxx
auth_kind: serviceaccount
service_account_file: /home/tim/xxxx.json

```

```
$ ansible-inventory --list -i dev.gcp.yml 
<returns info on the instances in json format>
```


[ansible inventory groups for gcp](https://devopscube.com/ansible-dymanic-inventry-google-cloud/)

Modify the gcp.yml file:

```
plugin: gcp_compute
projects:
  - healthy-reason-375613
auth_kind: serviceaccount
service_account_file: /home/tim/healthy-reason-375613-970326130116.json
keyed_groups:
  - key: labels
  - prefix: label
groups:
  development: "'environment' in (labels|list)"
```

check:

```
$ ansible-inventory --list | grep development -A4
            "development",
            "governorpilot",
            "governors",
            "odroid",
            "penduinopilot",
--
    "development": {
        "hosts": [
            "34.105.220.20"
        ]
    },
```

```
$  ansible development -m ping
The authenticity of host '34.105.220.20 (34.105.220.20)' can't be established.
ECDSA key fingerprint is SHA256:<snip>.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes 
34.105.220.20 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

We can [serve docker containers with systemd](https://jugmac00.github.io/blog/how-to-run-a-dockerized-service-via-systemd/) using someting like this (where %n is unit name without suffix):

```
[Unit]
Description=YouTrack Service
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=0
Restart=always
ExecStartPre=-/usr/bin/docker exec %n stop
ExecStartPre=-/usr/bin/docker rm %n
ExecStartPre=/usr/bin/docker pull jetbrains/youtrack:<version>
ExecStart=/usr/bin/docker run --rm --name %n \
    -v <path to data directory>:/opt/youtrack/data \
    -v <path to conf directory>:/opt/youtrack/conf \
    -v <path to logs directory>:/opt/youtrack/logs \
    -v <path to backups directory>:/opt/youtrack/backups \
    -p <port on host>:8080 \
    jetbrains/youtrack:<version>

[Install]
WantedBy=default.target
```

Or if using [docker compose](https://bootvar.com/systemd-service-for-docker-compose/)


```

[Unit]
Description=Service for myapp
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
WorkingDirectory=/root/bootvar
Environment=COMPOSE_HTTP_TIMEOUT=600
ExecStart=/usr/bin/env /usr/bin/docker-compose -f /root/bootvar/docker-compose.yml up -d
ExecStop=/usr/bin/env /usr/bin/docker-compose -f /root/bootvar/docker-compose.yml stop
StandardOutput=syslog
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

Except we want to always restart....?



Note we will need to handle CORS etc for nginx, if we are proxy passing to static web server ....[CORS on proxy pass nginx](https://stackoverflow.com/questions/45986631/how-to-enable-cors-in-nginx-proxy-server)

[certbot install playbook](https://devops.stackexchange.com/questions/3155/how-to-install-certbot-via-ansible-playbook)

```
- name: Add certbot repository
  apt_repository:
    repo: 'ppa:certbot/certbot'

- name: Install Certbot's Apache package
  apt:
    name: python-certbot-apache
    state: present
```

[with cron job for renewal](https://linuxbuz.com/linuxhowto/install-letsencrypt-ssl-ansible)

```
$ apt-get update
$ sudo apt-get install certbot
$ apt-get install python3-certbot-nginx
```

Mmmmm .... we will need the try_files directive for vue apps, which we know works. So ... [run git on a cronjob](https://gist.github.com/jazlopez/3106944230c539ae83d9905d8f76534b)?

```
# Git repository may not allow root to pull down updates
# Pull updates where $user is allowed to read/write remote.
# command line:
su -s /bin/sh $user -c 'cd /var/www/html/src && /usr/bin/git pull origin master'

# crontab (by executing sudo opens up root crontab)
sudo crontab -e 

# every 1 minute pull changes (if any)
*/1 * * * * su -s /bin/sh $user -c 'cd /var/www/html/src && /usr/bin/git pull origin master'
```

[Or use web-hooks?](http://joemaller.com/990/a-web-focused-git-workflow/) although this does not mention github


decision
- use host nginx to serve static files - try_files directive already works, alternatives seem painful
- run git pull on a cronjob every say 3min AND offer a playbook to do the update manually
- does rather run all developer's responsibilities together ... but ... manage by PR review?



 initial steps for nginx playbook from [mattiaslundberg]( https://gist.github.com/mattiaslundberg/ba214a35060d3c8603e9b1ec8627d349)
 but much simpler with certbot - none of the acme server stuff is needed

This is the initial nginx.conf after certbot has modified it.
 
```
 user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
	worker_connections 20000;
}

http {

	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 65;
	types_hash_max_size 2048;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	ssl_protocols TLSv1.2 TLSv1.3; 
	ssl_prefer_server_ciphers on;

	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;

	gzip on;

	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;
	client_max_body_size 0;

   
    server {
        server_name dev.practable.io;
        return 301 https://dev.practable.io$request_uri;
    
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/dev.practable.io/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/dev.practable.io/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

}
    



   
    server {
    if ($host = dev.practable.io) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


        listen 80;
        server_name dev.practable.io;
    return 404; # managed by Certbot


}}
```



## Checking things are working

on server
```
$ curl -XPOST localhost:4000/api/v1/users/unique
{"user_name":"cf7u7jeot5usefi5tig0"}
```

from admin machine

```
$ curl -XPOST https://dev.practable.io/book/api/v1/users/unique
{"code":404,"message":"path book/api/v1/users/unique was not found"}%  
```
[Need atrailing slash on the proxy path to remove the subdirectory](https://serverfault.com/questions/444532/reverse-proxy-remove-subdirectory)

e.g.
```
 location /book/api/ {
 <snip>
       proxy_pass          http://localhost:$BOOK_PORT/api/;
	   <snip>
```		   

This now works!

```
curl -XPOST https://dev.practable.io/book/api/v1/users/unique
{"user_name":"cf7uh06ot5usefi5tihg"}
```
