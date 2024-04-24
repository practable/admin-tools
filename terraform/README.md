# Terraform

Note that the status of the terraform project has recently changed and we may need to consider moving to an alternative.

## Helpful notes

### Running from new location

If using admin-tools from a new location or have re-pulled git repo:
run `terraform/app.practable.io/setup.sh` to symlink to ssl private key and cert in credentials repo
run `terraform init`
run `terraform plan` - should see that config matches state

### Updating an instance size in place

This took around 2m30s when upgrading `ed0` from `e2-highcpu-2` to `e2-standard-2`

## Background

Terraform represents hardware in code, which self-documents the setup of the cloud servers, and allows the usage of features that are not currently provided by the cloud GUI (e.g. load balancing special features that we need).

## Installation

The [installation information](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) covers multiple operating systems. We are currently using ubuntu on our admin machines.

The state is stored in a [gcs bucket](https://cloud.google.com/docs/terraform/resource-management/store-state), so it can be administered by multiple administrators - although there is the risk of race condition in terms of what changes are made/rolled-back when two try to make different changes at the same time.

terraform will need to be able to authenticate to the gcs bucket. If you don't do this, then the output looks like this:

```
terraform init   

Initializing the backend...
Initializing modules...
╷
│ Error: storage.NewClient() failed: dialing: google: could not find default credentials. See https://cloud.google.com/docs/authentication/external/set-up-adc for more information
```

These commands in this order do the login
```
gcloud auth login
gcloud init
gcloud auth application-default login
```

Then the `terraform init` runs ok:

```
Initializing the backend...

Successfully configured the backend "gcs"! Terraform will automatically
use this backend unless the backend configuration changes.
Initializing modules...

Initializing provider plugins...
- Finding latest version of hashicorp/tls...
- Finding hashicorp/random versions matching ">= 2.1.0, ~> 3.0"...
- Finding hashicorp/google versions matching ">= 3.43.0, >= 3.53.0, >= 4.50.0, < 5.0.0, < 6.0.0"...
- Finding hashicorp/google-beta versions matching ">= 3.43.0, >= 4.40.0, >= 4.50.0, < 5.0.0, < 6.0.0"...
- Finding latest version of hashicorp/template...
- Installing hashicorp/random v3.6.0...
- Installed hashicorp/random v3.6.0 (signed by HashiCorp)
- Installing hashicorp/google v4.84.0...
- Installed hashicorp/google v4.84.0 (signed by HashiCorp)
- Installing hashicorp/google-beta v4.84.0...
- Installed hashicorp/google-beta v4.84.0 (signed by HashiCorp)
- Installing hashicorp/template v2.2.0...
- Installed hashicorp/template v2.2.0 (signed by HashiCorp)
- Installing hashicorp/tls v4.0.5...
- Installed hashicorp/tls v4.0.5 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

To see what is currently in the system, type `terraform plan`:

```
<snip - lots of messages about refreshing state>
No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.
```