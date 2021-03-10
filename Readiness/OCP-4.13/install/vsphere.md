# Vsphere 4.13

## 4.5-4.12

```yaml

platform:
  vSphere:
    vcenter: ""
    datacenter: ""
    defaultDatastore: ""
    cluster: ""
    network: ""
    password: ""
    username: ""
    resourcePool: ""


```

## 4.13

```yaml

platform:
  vsphere:
    vcenters:
    - server: vcenter.sddc-44-236-21-251.vmwarevmc.com
      user: 'jcallen@ldap.vmc.ci.openshift.org'
      password: ''
      datacenters:
      - SDDC-Datacenter
    failureDomains:
    - name: single
      region: r1
      zone: z1
      server: vcenter.sddc-44-236-21-251.vmwarevmc.com
      topology:
        datacenter: SDDC-Datacenter
        datastore: "/SDDC-Datacenter/datastore/WorkloadDatastore"
        computeCluster: "/SDDC-Datacenter/host/Cluster-1"
        networks:
        - "dev-segment"
        folder: /SDDC-Datacenter/vm/jcallen

```

## Multi-Zone Tagging

```bash

# Create the tag categories
govc tags.category.create -d "OpenShift region" openshift-region
govc tags.category.create -d "OpenShift zone" openshift-zone

# Create the region tags
govc tags.create -c openshift-region us-east
govc tags.create -c openshift-region us-west

# Create the zone tags
govc tags.create -c openshift-zone us-east-1a
govc tags.create -c openshift-zone us-east-2a
govc tags.create -c openshift-zone us-east-3a
govc tags.create -c openshift-zone us-west-1a

# Attach the region tags to vCenter datacenters
govc tags.attach -c openshift-region us-east /IBMCloud
govc tags.attach -c openshift-region us-west /datacenter-2

# Attach the zone tags to vCenter clusters
govc tags.attach -c openshift-zone us-east-1a /IBMCloud/host/vcs-mdcnc-workload-1
govc tags.attach -c openshift-zone us-east-2a /IBMCloud/host/vcs-mdcnc-workload-2
govc tags.attach -c openshift-zone us-east-3a /IBMCloud/host/vcs-mdcnc-workload-3
govc tags.attach -c openshift-zone us-west-1a /datacenter-2/host/vcs-mdcnc-workload-4


```

## Multi-Zone install-config.yaml

```yaml

apiVersion: v1
baseDomain: vmc.devcluster.openshift.com
metadata:
  name: jcallen2
controlPlane:
  name: master
  replicas: 3
  platform:
    vsphere:
      zones:
      - "us-east-1"
      - "us-east-2"
      - "us-east-3"
compute:
- name: worker
  replicas: 3
  platform:
    vsphere:
      zones:
      - "us-east-2"
      - "us-east-3"
      - "us-west-1"
platform:
  vSphere:
    vcenters: []
    failureDomains: []

```
