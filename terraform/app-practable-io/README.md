# app.practable.io

## SSL Certificate update

For seamless swap of certificates, including no interruption to existing experiments that are streaming (we checked on 19-08-2025), the process is as follows:

0. obtain new wildcard (or multidomain) ssl cert (see below)
1. add new certificate in main.tf using symlinks (see below)
2. add that cert to the list of certs used by the load balancer
0. run 'terraform plan' and apply if it looks ok
0. check everything still ok
0. remove old certificate from the list of certs used by the load balancer
0. run 'terraform plan' and apply if it looks ok
0. check that new cert is served by opening a private tab (avoids the cached old cert you will get in a regular tab) 

Note that a running pendulum experiment showed no disruption during either of the terraform apply actions, therefore this should be able to be done during a period of production if needed.

## Getting new ssl cert

0. go to credentials repo
0. copy the last year's directory into a new directory e.g. 2026-04
1. go to the new directory
2. delete the keys, pem, crt and csr files 
3. run create_csr.sh
4. obtain ssl using csr
5. copy the bundle and crt files from the ssl supplier into this directory
6. run make_pem.sh
7. commit and push changes to credentials repo
0. edit setup.sh  (in this terraform dir) to point to provide dated symlinks to the new key and pem


## Load balancer setup based on HTTP-to-HTTPS Redirect Example

[![button](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/GoogleCloudPlatform/terraform-google-lb-http&working_dir=examples/https-redirect&page=shell&tutorial=README.md)

This example shows how to enable HTTPS redirection on Google external
HTTP(S) load balancers.

### Change to the example directory

```
[[ `basename $PWD` != https-redirect ]] && cd examples/https-redirect
```

### Install Terraform

1. Install Terraform if it is not already installed (visit [terraform.io](https://terraform.io) for other distributions):

### Set up the environment

1. Set the project, replace `YOUR_PROJECT` with your project ID:

```
PROJECT=YOUR_PROJECT
```

```
gcloud config set project ${PROJECT}
```

2. Configure the environment for Terraform:

```
[[ $CLOUD_SHELL ]] || gcloud auth application-default login
export GOOGLE_PROJECT=$(gcloud config get-value project)
```

### Run Terraform

```
terraform init
terraform apply
```

### Testing

1. Open URL of load balancer in browser:

```
echo http://$(terraform output load-balancer-ip)| sed 's/"//g'
```

> You should see the Google Cloud logo and instance details.

### Cleanup

1. Remove all resources created by Terraform:

```
terraform destroy
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| network\_name | n/a | `string` | `"tf-lb-https-redirect-nat"` | no |
| project | n/a | `string` | n/a | yes |
| region | n/a | `string` | `"us-east1"` | no |

### Outputs

| Name | Description |
|------|-------------|
| backend\_services | n/a |
| load-balancer-ip | n/a |
| load-balancer-ipv6 | The IPv6 address of the load-balancer, if enabled; else "undefined" |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
