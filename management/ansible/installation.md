# Installation

## Ansible

~~~bash
# ansible > 2.9
$ pip install --upgrade ansible
~~~

## k8s plugins

~~~bash

$ ansible-galaxy collection install community.kubernetes
$ ansible-galaxy collection install kubernetes.core

~~~

## Python Modules

~~~bash

python >= 2.7
openshift >= 0.6
PyYAML >= 3.11

$ pip install openshift --user

~~~

## Test

~~~bash

$ ./01-playbook.yaml --tags apply-01 -vv

PLAY RECAP ********************************************************************************************************************************************************************************************************
localhost                  : ok=8    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

$ oc get oauth cluster -o yaml

apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  annotations:
    include.release.openshift.io/ibm-cloud-managed: "true"
    include.release.openshift.io/self-managed-high-availability: "true"
    include.release.openshift.io/single-node-developer: "true"
    release.openshift.io/create-only: "true"
  creationTimestamp: "2022-09-01T05:15:56Z"
  generation: 2
  name: cluster
  resourceVersion: "5951032"
  uid: 90f601aa-d4b2-4745-9809-8069f97aa6cc
spec:
  identityProviders:
  - htpasswd:
      fileData:
        name: htpasswd
    mappingMethod: claim
    name: Local
    type: HTPasswd
  tokenConfig:
    accessTokenMaxAgeSeconds: 31104000

~~~
