# Configure SR-IOV using Ansible Playbook

## Network Topology

The SR-IOV device is enp130s0f0 and it connects to vlan 183 with 10.72.51.0/27 subnet and 10.72.51.30 as the gateway. The roles of the ansible are not visible in this repo.

## Ansible Playbook

```bash

$ cat vars.yaml

cluster_name: sno-pek
public_domain: ocp.com
cpu_isolated: 2-15,18-31
cpu_reserved: 0-1,16-17
hugepages_count: 8
sriov_definitions:
- policyName: 'sriov-config-netdevice-enp130s0f0'
  devType: 'netdevice'
  devName: 'enp130s0f0'
  numVfs: 8
  vfs: '0-7'

$ cat playbook.yaml

#!/usr/bin/env ansible-playbook
---
- name: Configure OpenShift Container Platform SR-IOV
  hosts: localhost
  connection: local
  gather_facts: true
  environment:
    PATH: "/usr/bin/:/usr/local/bin/:{{ ansible_env.PATH }}"
  vars_files:
    - ./vars.yaml
  vars:
    kubeconfig: "{{ ansible_env.KUBECONFIG }}"
    k8s_validate_certs: false
  roles:
    - role: ocp4-configure-required-modules
      tags: apply-01
    - role: ocp4-configure-sriov-operator
      tags: apply-02
    - role: ocp4-configure-sriov-devices
      tags: apply-03
    - role: ocp4-configure-pao-operator
      tags: apply-04

$ export KUBECONFIG=kubeconfig

$ ./playbook.yaml --tags apply01
$ ./playbook.yaml --tags apply02
$ ./playbook.yaml --tags apply03
$ ./playbook.yaml --tags apply04

```

## Create SR-IOV Network

```bash

$ cat sriovnetwork.yaml
apiVersion: sriovnetwork.openshift.io/v1
kind: SriovNetwork
metadata:
  name: sriov-intel
  namespace: openshift-sriov-network-operator
spec:
  ipam: |
    {
      "type": "host-local",
      "subnet": "10.72.51.0/27",
      "rangeStart": "10.72.51.25",
      "rangeEnd": "10.72.51.29",
      "routes": [{
        "dst": "0.0.0.0/0"
      }],
      "gateway": "10.72.51.30"
    }
  vlan: 183
  spoofChk: "off"
  resourceName: sriov_netdevice_enp130s0f0
  networkNamespace: default

$ oc apply -f sriovnetwork.yaml

$ oc get net-attach-def -n default

```

## Create POD

```bash

$ cat pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: sriovpod1
  annotations:
    k8s.v1.cni.cncf.io/networks: |-
      [
        {
          "name": "sriov-intel",
          "default-route": ["10.72.51.30"]
        }
      ]
spec:
  containers:
  - name: appcntr1
    image: centos/tools
    imagePullPolicy: IfNotPresent
    command: [ "/bin/bash", "-c", "--" ]
    args: [ "while true; do sleep 300000; done;" ]
    securityContext:
      capabilities:
        add: ["NET_RAW", "NET_ADMIN"]

$ oc project default
$ oc apply -f pod.yaml

$ oc rsh sriovpod1
sh-4.2# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
3: eth0@if103: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default
    link/ether 0a:58:0a:80:00:4a brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.128.0.74/23 brd 10.128.1.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::8cce:ebff:fe9a:dae/64 scope link
       valid_lft forever preferred_lft forever
94: net1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 8a:b9:db:5e:79:f0 brd ff:ff:ff:ff:ff:ff
    inet 10.72.51.26/27 brd 10.72.51.31 scope global net1
       valid_lft forever preferred_lft forever
    inet6 fe80::88b9:dbff:fe5e:79f0/64 scope link
       valid_lft forever preferred_lft forever

sh-4.2# ip route
default via 10.72.51.30 dev net1
10.72.46.0/24 via 10.128.0.1 dev eth0
10.72.51.0/27 dev net1 proto kernel scope link src 10.72.51.26
10.128.0.0/23 dev eth0 proto kernel scope link src 10.128.0.74
10.128.0.0/14 dev eth0
172.30.0.0/16 via 10.128.0.1 dev eth0
224.0.0.0/4 dev eth0

sh-4.2# ping 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=48 time=50.0 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=48 time=50.4 ms

```
