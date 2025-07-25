# Fast IPAM in whereabouts

<https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking/index#nw-multus-whereabouts-fast-ipam_configuring-additional-network>

## Enable whereabouts

```bash

$ oc edit network.operator

  additionalNetworks:
  - name: whereabouts-shim
    namespace: default
    rawCNIConfig: |-
      {
       "name": "whereabouts-shim",
       "cniVersion": "0.3.1",
       "type": "bridge",
       "ipam": {
         "type": "whereabouts"
       }
      }
    type: Raw

$ oc get pods -n openshift-multus | grep controller
whereabouts-controller-5cbfd6c475-fr7d7        1/1     Running            0             112s

```

## Create NAD and Pod

```bash

$ oc apply -f files/nad.yaml
networkattachmentdefinition.k8s.cni.cncf.io/wb-ipam created

$ oc apply -f files/pod.yaml
pod/fastipam-pod created

```

## Test

```bash

oc rsh fastipam-pod
sh-4.4# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0@if438: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 8901 qdisc noqueue state UP group default
    link/ether 0a:58:0a:80:03:ae brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.128.3.174/23 brd 10.128.3.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::858:aff:fe80:3ae/64 scope link
       valid_lft forever preferred_lft forever
3: net1@if439: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 1a:04:6f:a4:15:3c brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.5.0.1/20 brd 10.5.15.255 scope global net1
       valid_lft forever preferred_lft forever
    inet6 fe80::1804:6fff:fea4:153c/64 scope link
       valid_lft forever preferred_lft forever

```

```bash

$ oc get nodeslicepool -n openshift-multus
NAME               AGE
wb-ipam-cni-name   4m20s

$ oc get nodeslicepool -n openshift-multus wb-ipam-cni-name -o yaml
apiVersion: whereabouts.cni.cncf.io/v1alpha1
kind: NodeSlicePool
metadata:
  creationTimestamp: "2025-07-25T02:39:24Z"
  generation: 1
  name: wb-ipam-cni-name
  namespace: openshift-multus
  ownerReferences:
  - apiVersion: k8s.cni.cncf.io/v1
    blockOwnerDeletion: true
    controller: true
    kind: NetworkAttachmentDefinition
    name: wb-ipam
    uid: d74ae61d-47b3-41fd-9ae3-b97c93720d71
  resourceVersion: "1778509"
  uid: 923d32e0-1f3b-4a29-866e-494026959137
spec:
  range: 10.5.0.0/20
  sliceSize: /24
status:
  allocations:
  - nodeName: ip-10-0-17-136.us-east-2.compute.internal
    sliceRange: 10.5.0.0/24
  - nodeName: ip-10-0-2-97.us-east-2.compute.internal
    sliceRange: 10.5.1.0/24
  - nodeName: ip-10-0-38-165.us-east-2.compute.internal
    sliceRange: 10.5.2.0/24
  - nodeName: ip-10-0-54-209.us-east-2.compute.internal
    sliceRange: 10.5.3.0/24
  - nodeName: ip-10-0-75-178.us-east-2.compute.internal
    sliceRange: 10.5.4.0/24
  - nodeName: ""
    sliceRange: 10.5.5.0/24
  - nodeName: ""
    sliceRange: 10.5.6.0/24
  - nodeName: ""
    sliceRange: 10.5.7.0/24
  - nodeName: ""
    sliceRange: 10.5.8.0/24
  - nodeName: ""
    sliceRange: 10.5.9.0/24
  - nodeName: ""
    sliceRange: 10.5.10.0/24
  - nodeName: ""
    sliceRange: 10.5.11.0/24
  - nodeName: ""
    sliceRange: 10.5.12.0/24
  - nodeName: ""
    sliceRange: 10.5.13.0/24
  - nodeName: ""
    sliceRange: 10.5.14.0/24
  - nodeName: ""
    sliceRange: 10.5.15.0/24

```