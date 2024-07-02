# admin-tools

This repo contains documentation and scripts for setting up and operating the official practable.io cloud service. The primary audience for this document is the core developer and operations team.
 
## Repo Contents

The configuration and tools for each instance are held in separate directories, to minimise accidental operations on the wrong instance (a. 

```
├── config: git-secrets pre-commit hook setup
├── dev: setup and admin tools for the development instance `dev`
├── ed0: setup and admin tools for the production instance `ed0`
├── ed-dev-ui: setup and admin tools for the development instance `ed-dev-ui`
├── terraform: infrastructure described as code
└── img: images for README.md
```

Organising the files in this way has some small advantages

- safety
    -  any operations are performed on the instance associated with your current working directory
    -  this avoids inadvertently running a playbook on the wrong instance e.g. by using command line history incorrectly
- convenience
    -  we can modify the development server configuration, scripts and tools without being constrained by the production version
	-  differences between instances can be determined via diff operation, e.g. on the configuration script

## Setting up

### configure git-secrets hook

See [hook config instructions](./config/README.md) to set up a pre-commit hook that detects some common cases of leaked secrets, before they are committed.

If you have leaked a secret by committing it, no matter how briefly, then you will need to arrange for [cleaning of the repo history](https://rtyley.github.io/bfg-repo-cleaner/) so that it cannot be found in future.

### install gcloud cli

[install gcloud cli](https://cloud.google.com/sdk/docs/install)

run the init script, authenticate in the browser when asked, then select the appropriate project hosting the infrastructure
```
gcloud init
```

### install ansible

[install instructions](https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html)

### configure dynamic inventory

Ansible support is [described here](https://docs.ansible.com/ansible/latest/scenario_guides/guide_gce.html)

```
$ pip install requests google-auth
```

As per [doc]((https://docs.ansible.com/ansible/latest/scenario_guides/guide_gce.html) In GCP console, Select the project, service account, then go the keys tab and download a JSON key

Then add to `/etc/ansible/ansible.cfg` the following (must include all the default plugins to still be able to parse the standard hosts file)

```
[defaults]
inventory      = /opt/ansible/inventory/gcp.yaml

[inventory]
enable_plugins = gcp_compute, host_list, script, auto, yaml, ini, toml 
```

We want to define groups that we can run playbooks against. We can do that by creating`/opt/ansible/inventory/gcp.yaml` and using the instance name, although there are other options such as tags if there are multiple instances in each group ([more info](https://devopscube.com/ansible-dymanic-inventry-google-cloud/)) 




```
plugin: gcp_compute
projects:
  - app-practable-io-alpha
auth_kind: serviceaccount
service_account_file: /home/tim/secret/app.practable.io/app-practable-io-alpha-84a62509ce73.json
keyed_groups:
  - key: labels
  - prefix: label
groups:
  development: "'environment' in (labels|list)"
  app_practable_dev: "'app-practable-io-alpha-dev' in name"
  app_practable_ed0: "'app-practable-io-alpha-ed0' in name"
  app_practable_ed_dev_ui: "'app-practable-io-alpha-ed-dev-ui' in name"
```


```
$ ansible-inventory --list 
<returns info on the instances in json format>
```


```
$ ansible-inventory --graph 
@all:
<snip>
  |--@app_practable_dev:
  |  |--34.147.137.222
  |--@app_practable_ed0:
  |  |--34.142.59.89
<snip>
```


```
$  ansible app-practable-dev -m ping
34.147.137.222 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
$ ansible app_practable_ed0 -m ping  
34.142.59.89 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

### install terraform

[installation instructions](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)


### prepare to administer an instance

Go to the directory associated with the isntance. Usually you need to run

```
./install.sh && ./configure.sh
```

### Prepare to alter the infrastructure

go to the terraform directory, then the appropriate subdirectory

```
terraform init
```



## Helpful procedures

Here are some [helpful procedures](./PROCEDURES.md) for checking/restarting services.



## Architecture

Some further description of the [architecture](ARCHITECTURE.md) for those making modifications to the infrastructure.

