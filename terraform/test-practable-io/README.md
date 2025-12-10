# test-practable-io

The purpose of this infrastructure is provide a separate environment for load testing.

## Project

We'll do this in a separate project


Check current project ID

```
gcloud projects list --sort-by=projectId --limit=5
```

Choose project Id as `test-practable-io-alpha`

```
gcloud projects create test-practable-io-alpha
```

List billing accounts:

```
gcloud billing accounts list
```

```
gcloud billing projects link test-practable-io-alpha --billing-account=xxxxxx
```

update quota project to be this project now we're working on this project for now

```
gcloud auth application-default set-quota-project ${PROJECT}
```

We need storage for our terraform bucket
```
gcloud services enable storage.googleapis.com
```

enable compute & IAM APIs

add Service Account User role to individual's account in IAM section of the project

