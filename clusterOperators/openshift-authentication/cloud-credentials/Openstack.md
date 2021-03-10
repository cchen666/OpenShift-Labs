# OpenStack Cloud Credentials

## Check OpenStack Cloud Credentials

```bash

$ oc get secret openstack-credentials -o yaml -n kube-system

```

## Change the OpenStack Cloud Credentials

```bash

$ cat files/clouds.yaml | base64

$ oc edit secret openstack-credentials -n kube-system
data:
  clouds.conf: <base64 encoded string>
  clouds.yaml: <base64 encoded string>

```
