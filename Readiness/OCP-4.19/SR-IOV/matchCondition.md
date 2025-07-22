# resourceInjectorMatchCondition

## Install SR-IOV Operator

## Create SR-IOV Operator Config

```bash

apiVersion: sriovnetwork.openshift.io/v1
kind: SriovOperatorConfig
metadata:
  creationTimestamp: "2025-07-21T10:19:24Z"
  finalizers:
  - operatorconfig.finalizers.sriovnetwork.openshift.io
  generation: 2
  name: default
  namespace: openshift-sriov-network-operator
  resourceVersion: "139338"
  uid: d3603400-52c8-42d3-9830-78c7422757b1
spec:
  configurationMode: daemon
  disableDrain: false
  enableInjector: true
  enableOperatorWebhook: true
  logLevel: 2

```

## Create SR-IOV Network Node Policy

```bash

apiVersion: sriovnetwork.openshift.io/v1
kind: SriovNetworkNodePolicy
metadata:
  name: sriov-config-netdevice-enp130s0f0
  namespace: openshift-sriov-network-operator
spec:
  deviceType: netdevice
  isRdma: false
  linkType: eth
  mtu: 1500
  nicSelector:
    pfNames:
    - enp130s0f0#0-7
  nodeSelector:
    feature.node.kubernetes.io/network-sriov.capable: "true"
  numVfs: 8
  priority: 50
  resourceName: sriov_netdevice_enp130s0f0

```

## Confirm the VFs have been created

```bash

$ ip l show enp130s0f0
6: enp130s0f0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
    link/ether a0:36:9f:e3:ff:1c brd ff:ff:ff:ff:ff:ff
    vf 0     link/ether 00:00:00:00:00:00 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off, query_rss off
    vf 1     link/ether 1e:13:81:f6:de:97 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off, query_rss off
    vf 2     link/ether 66:c4:c1:08:c6:8f brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off, query_rss off
    vf 3     link/ether 52:74:d8:0f:d7:24 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off, query_rss off
    vf 4     link/ether c6:3a:73:62:86:13 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off, query_rss off
    vf 5     link/ether 4a:a2:7d:c7:82:c8 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off, query_rss off
    vf 6     link/ether 46:83:7f:df:d7:00 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off, query_rss off
    vf 7     link/ether da:ef:f6:0c:31:a7 brd ff:ff:ff:ff:ff:ff, spoof checking on, link-state auto, trust off, query_rss off

```

## Edit SR-IOV Operator Config to enable resourceInjectorMatchCondition

```bash

$ oc edit sriovoperatorconfig default -n openshift-sriov-network-operator
<Snip>
spec:
  configurationMode: daemon
  disableDrain: false
  enableInjector: true
  enableOperatorWebhook: true
  featureGates:
    resourceInjectorMatchCondition: true
  logLevel: 2

```

## Confirm the resourceInjectorMatchCondition is enabled in logs

```bash

$ oc logs -n openshift-sriov-network-operator -l name=sriov-network-operator

2025-07-22T02:29:46.860422227Z  INFO    controller/controller.go:118    enabled featureGates    {"controller": "sriovoperatorconfig", "controllerGroup":
 "sriovnetwork.openshift.io", "controllerKind": "SriovOperatorConfig", "SriovOperatorConfig": {"name":"default","namespace":"openshift-sriov-network-ope
rator"}, "namespace": "openshift-sriov-network-operator", "name": "default", "reconcileID": "f70298e7-3e4c-412a-b474-2146e129e8ab", "sriovoperatorconfig
": {"name":"default","namespace":"openshift-sriov-network-operator"}, "featureGates": ""}

2025-07-22T02:34:35.815551107Z  INFO    controller/controller.go:118    Reconciling SriovOperatorConfig {"controller": "sriovoperatorconfig", "controlle
rGroup": "sriovnetwork.openshift.io", "controllerKind": "SriovOperatorConfig", "SriovOperatorConfig": {"name":"default","namespace":"openshift-sriov-net
work-operator"}, "namespace": "openshift-sriov-network-operator", "name": "default", "reconcileID": "28256715-2fe3-48e2-b6ef-980c46316247", "sriovoperat
orconfig": {"name":"default","namespace":"openshift-sriov-network-operator"}}
2025-07-22T02:34:35.815894546Z  INFO    controller/controller.go:118    enabled featureGates    {"controller": "sriovoperatorconfig", "controllerGroup": "sriovnetwork.openshift.io", "controllerKind": "SriovOperatorConfig", "SriovOperatorConfig": {"name":"default","namespace":"openshift-sriov-network-operator"}, "namespace": "openshift-sriov-network-operator", "name": "default", "reconcileID": "28256715-2fe3-48e2-b6ef-980c46316247", "sriovoperatorconfig": {"name":"default","namespace":"openshift-sriov-network-operator"}, "featureGates": "resourceInjectorMatchCondition:true"}

```
