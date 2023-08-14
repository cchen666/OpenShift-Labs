# Installation

## rosa login

```bash
$ rosa login --token="<your token>"
```

## rosa whoami

```bash
$ rosa whoami

AWS Account ID:               12345678
AWS Default Region:           us-east-2
AWS ARN:                      arn:aws:iam::1234567:user/cchen
OCM API:                      https://api.openshift.com
OCM Account ID:               1234567
OCM Account Name:             Chen Chen
OCM Account Username:         rhn-support-cchen
OCM Account Email:            cchen@redhat.com
OCM Organization ID:          1234567
OCM Organization Name:        Red Hat
OCM Organization External ID: 1234567


## rosa verify

```bash
$  rosa verify permissions
I: Validating SCP policies...
I: AWS SCP policies ok

$  rosa verify quota --region=us-east-2
I: Validating AWS quota...
I: AWS quota ok. If cluster installation fails, validate actual AWS resource usage against https://docs.openshift.com/rosa/rosa_getting_started/rosa-required-aws-service-quotas.html

```

## rosa init

```bash
$ rosa init
I: Logged in as 'rhn-support-cchen' on 'https://api.openshift.com'
I: Validating AWS credentials...
I: AWS credentials are valid!
I: Validating SCP policies...
I: AWS SCP policies ok
I: Validating AWS quota...
I: AWS quota ok. If cluster installation fails, validate actual AWS resource usage against https://docs.openshift.com/rosa/rosa_getting_started/rosa-required-aws-service-quotas.html
I: Ensuring cluster administrator user 'osdCcsAdmin'...
I: Admin user 'osdCcsAdmin' already exists!
I: Validating SCP policies for 'osdCcsAdmin'...
I: AWS SCP policies ok
I: Validating cluster creation...
I: Cluster creation valid
I: Verifying whether OpenShift command-line tool is available...
I: Current OpenShift Client Version: 4.8.17
```

## rosa create cluster

```bash

$ rosa create cluster --cluster-name=cchen-rosa

I: Creating cluster 'cchen-rosa'
I: To view a list of clusters and their status, run 'rosa list clusters'
I: Cluster 'cchen-rosa' has been created.
I: Once the cluster is installed you will need to add an Identity Provider before you can login into the cluster. See 'rosa create idp --help' for more information.
I: To determine when your cluster is Ready, run 'rosa describe cluster -c cchen-rosa'.
I: To watch your cluster installation logs, run 'rosa logs install -c cchen-rosa --watch'.
Name:                       cchen-rosa
ID:                         1234567
External ID:
OpenShift Version:
Channel Group:              stable
DNS:                        cchen-rosa.1234.p1.openshiftapps.com
AWS Account:                12345678
API URL:
Console URL:
Region:                     us-east-2
Multi-AZ:                   false
Nodes:
 - Control plane:           3
 - Infra:                   2
 - Compute:                 2
Network:
 - Service CIDR:            172.30.0.0/16
 - Machine CIDR:            10.0.0.0/16
 - Pod CIDR:                10.128.0.0/14
 - Host Prefix:             /23
State:                      pending (Preparing account)
Private:                    No
Created:                    Nov  1 2021 12:38:02 UTC
Details Page:               https://console.redhat.com/openshift/details/s/12345678

```

## Create admin user

```bash
$ rosa create admin --cluster=cchen-rosa
```
