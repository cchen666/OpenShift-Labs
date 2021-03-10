# SR-IOV Lab in Single Node OpenShift

Firstly check Demo1 Operator Config <https://asciinema.org/a/293746> Demo2 With Numa <https://asciinema.org/a/293766> which are created by Zenghui Shi

## Enable SR-IOV in BIOS

This includes not only server's BIOS, but also device BIOS.

## Enable iommu kernel args

~~~bash

$ cat <<EOF > mc-iommu.yaml

apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master # This is for SNO or 3-node
  name: mc-mmu-kernel-args
spec:
  config:
    ignition:
      version: 3.2.0
  kernelArguments:
  - intel_iommu=on
  - iommu=pt

EOF

$ oc apply -f mc-iommu.yaml

# Wait for the server reboot
~~~

## Create SR-IOV Network Operator

~~~bash

$ cat << EOF > sriov-operator.yaml

---
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-sriov-network-operator
  annotations:
    workload.openshift.io/allowed: management

---

apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: sriov-network-operators
  namespace: openshift-sriov-network-operator
spec:
  targetNamespaces:
  - openshift-sriov-network-operator

---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: sriov-network-operator-subscription
  namespace: openshift-sriov-network-operator
spec:
  channel: "4.8"
  installPlanApproval: Automatic
  name: sriov-network-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace

EOF

$ oc apply -f sriov-operator.yaml

# After creating the operator you should see following 3 types of PODs.
# network-resources-injector: Admission hook to inject labels automatically
# operator-webhook: Admission webhook to validate the SriovNetworkPolicy definition valid or not
# sriov-network-config-daemon: Daemonsets run on each worker node to do the configuration work


$ oc get pods -n openshift-sriov-network-operator
NAME                                    READY   STATUS    RESTARTS   AGE
network-resources-injector-5tfcn        1/1     Running   2          5h59m
operator-webhook-r2d5t                  1/1     Running   2          5h59m
sriov-network-config-daemon-6t2l7       1/1     Running   2          5h59m
sriov-network-operator-6947d96c-rl5qr   1/1     Running   2          5h59m

# Both injector and operator-webhook can be disabled on your demand by configuring sriovoperatorconfigs:

$ oc edit sriovoperatorconfigs default
apiVersion: sriovnetwork.openshift.io/v1
kind: SriovOperatorConfig
metadata:
  creationTimestamp: "2021-10-13T03:02:04Z"
  generation: 1
  name: default
  namespace: openshift-sriov-network-operator
  resourceVersion: "217442"
  uid: a56726b5-f5c3-4fa0-b7b5-7a213904d802
spec:
  enableInjector: true          <-------
  enableOperatorWebhook: true   <-------
  logLevel: 2

~~~

## Create SR-IOV Network Policy

~~~bash

# First get the SriovNetworkNodeState CR to see whether the VFs have been identified by the server:

$ oc get crd |grep sriov
sriovibnetworks.sriovnetwork.openshift.io                         2021-10-13T03:01:25Z
sriovnetworknodepolicies.sriovnetwork.openshift.io                2021-10-13T03:01:25Z
sriovnetworknodestates.sriovnetwork.openshift.io                  2021-10-13T03:01:25Z
sriovnetworks.sriovnetwork.openshift.io                           2021-10-13T03:01:25Z
sriovoperatorconfigs.sriovnetwork.openshift.io                    2021-10-13T03:01:25Z

$ oc get sriovnetworknodestates
NAME                                 AGE
dell-r740-01.gsslab.brq.redhat.com   9h

$ oc get sriovnetworknodestates dell-r740-01.gsslab.brq.redhat.com -o yaml

<Snip>

  - deviceID: "1572"
    driver: i40e
    linkSpeed: 10000 Mb/s
    linkType: ETH
    mac: f8:f2:1e:49:49:a1
    mtu: 1500
    name: ens1f1
    pciAddress: 0000:3b:00.1
    totalvfs: 64           <---------
    vendor: "8086"

# In the above sample output the totalvfs is 64. In other way you can confirm SR-IOV has been correctly configured by running

$ cat /sys/class/net/ens1f0/device/sriov_totalvfs
64

# Then we create SriovNetworkNodePolicy

$ cat << EOF > policy.yaml

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

EOF

# After the Policy is created, two more PODs will be created
# sriov-cni: it provides a binary `sriov` and copy it to host:

$ ls /var/lib/cni/bin/
bandwidth  dhcp           firewall  host-device  ib-sriov  loopback  multus         portmap  route-override  sriov   tuning  vrf
bridge     egress-router  flannel   host-local   ipvlan    macvlan   openshift-sdn  ptp      sbr             static  vlan    whereabouts

# sriov-device-plugin: SR-IOV CNI plugin works with SR-IOV device plugin for VF allocation in Kubernetes. A metaplugin such as Multus
# gets the allocated VF's deviceID(PCI address) and is responsible for invoking the SR-IOV CNI plugin with that deviceID.

# More details: https://github.com/openshift/sriov-cni, https://segmentfault.com/a/1190000021061494

$ oc apply -f policy.yaml

$ oc get pods -n openshift-sriov-network-operator
NAME                                    READY   STATUS    RESTARTS   AGE
network-resources-injector-5tfcn        1/1     Running   2          6h
operator-webhook-r2d5t                  1/1     Running   2          6h
sriov-cni-lczs4                         2/2     Running   0          5h25m
sriov-device-plugin-gbhz2               1/1     Running   0          5h24m
sriov-network-config-daemon-6t2l7       1/1     Running   2          6h
sriov-network-operator-6947d96c-rl5qr   1/1     Running   2          6h1m

$ oc logs sriov-device-plugin-gbhz2

<Snip> # The logs show 8 VFs are created

I1013 07:23:56.979871       1 manager.go:116] Creating new ResourcePool: sriov_netdevice_ens1f0
I1013 07:23:56.979874       1 manager.go:117] DeviceType: netDevice
I1013 07:23:56.983592       1 factory.go:108] device added: [pciAddr: 0000:3b:02.0, vendor: 8086, device: 154c, driver: iavf]
I1013 07:23:56.983603       1 factory.go:108] device added: [pciAddr: 0000:3b:02.1, vendor: 8086, device: 154c, driver: iavf]
I1013 07:23:56.983607       1 factory.go:108] device added: [pciAddr: 0000:3b:02.2, vendor: 8086, device: 154c, driver: iavf]
I1013 07:23:56.983610       1 factory.go:108] device added: [pciAddr: 0000:3b:02.3, vendor: 8086, device: 154c, driver: iavf]
I1013 07:23:56.983614       1 factory.go:108] device added: [pciAddr: 0000:3b:02.4, vendor: 8086, device: 154c, driver: iavf]
I1013 07:23:56.983619       1 factory.go:108] device added: [pciAddr: 0000:3b:02.5, vendor: 8086, device: 154c, driver: iavf]
I1013 07:23:56.983623       1 factory.go:108] device added: [pciAddr: 0000:3b:02.6, vendor: 8086, device: 154c, driver: iavf]
I1013 07:23:56.983626       1 factory.go:108] device added: [pciAddr: 0000:3b:02.7, vendor: 8086, device: 154c, driver: iavf]

~~~

## Create SRIOV Network CR

~~~bash

$ oc new-project test-1

$ cat << EOF > sriov-network.yaml

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

EOF

$ oc apply -f sriov-network.yaml

# A network-attachment-definitions CR will be created automatically to map the SRIOV Network

$ oc get net-attach-def -n test-1
NAME              AGE
example-network   23m
~~~

## Create PODs using example-network

~~~bash

# In metadata.annotations we specify the network we created previously

$ cat << EOF > pod.yaml

---

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
      privileged: true

---

apiVersion: v1
kind: Pod
metadata:
  name: sriovpod2
  namespace: test-1
  annotations:
    k8s.v1.cni.cncf.io/networks: example-network
spec:
  containers:
  - name: appcntr1
    image: centos/tools
    imagePullPolicy: IfNotPresent
    command: [ "/bin/bash", "-c", "--" ]
    args: [ "while true; do sleep 300000; done;" ]

EOF

$ oc apply -f pod.yaml

$ oc get pods
NAME        READY   STATUS    RESTARTS   AGE
sriovpod1   1/1     Running   0          19m
sriovpod2   1/1     Running   0          16m

# Check the additional network is attached

$ oc describe pod sriovpod1

Events:
  Type    Reason          Age   From               Message
  ----    ------          ----  ----               -------
  Normal  Scheduled       20m   default-scheduler  Successfully assigned test-1/sriovpod1 to dell-r740-01.gsslab.brq.redhat.com
  Normal  AddedInterface  20m   multus             Add eth0 [10.128.0.178/23] from openshift-sdn
  Normal  AddedInterface  20m   multus             Add net1 [10.56.217.171/24] from test-1/example-network
  Normal  Pulling         20m   kubelet            Pulling image "centos/tools"
  Normal  Pulled          19m   kubelet            Successfully pulled image "centos/tools" in 52.25957321s
  Normal  Created         19m   kubelet            Created container appcntr1
  Normal  Started         19m   kubelet            Started container appcntr1

$ oc describe pod sriovpod2

Events:
  Type    Reason          Age   From               Message
  ----    ------          ----  ----               -------
  Normal  Scheduled       17m   default-scheduler  Successfully assigned test-1/sriovpod2 to dell-r740-01.gsslab.brq.redhat.com
  Normal  AddedInterface  17m   multus             Add eth0 [10.128.0.179/23] from openshift-sdn
  Normal  AddedInterface  17m   multus             Add net1 [10.56.217.172/24] from test-1/example-network
  Normal  Pulled          17m   kubelet            Container image "centos/tools" already present on machine
  Normal  Created         17m   kubelet            Created container appcntr1
  Normal  Started         17m   kubelet            Started container appcntr1

# Try to ping pod2's IP in pod1

$ oc rsh sriovpod1
sh-4.2# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
3: eth0@if208: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default
    link/ether 0a:58:0a:80:00:b2 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.128.0.178/23 brd 10.128.1.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::e85a:28ff:fe1d:f7ac/64 scope link
       valid_lft forever preferred_lft forever
95: net1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 4e:94:a7:b6:12:02 brd ff:ff:ff:ff:ff:ff
    inet 10.56.217.171/24 brd 10.56.217.255 scope global net1
       valid_lft forever preferred_lft forever
    inet6 fe80::4c94:a7ff:feb6:1202/64 scope link
       valid_lft forever preferred_lft forever

sh-4.2# ping 10.56.217.172
PING 10.56.217.172 (10.56.217.172) 56(84) bytes of data.
64 bytes from 10.56.217.172: icmp_seq=1 ttl=64 time=0.087 ms
64 bytes from 10.56.217.172: icmp_seq=2 ttl=64 time=0.069 ms
64 bytes from 10.56.217.172: icmp_seq=3 ttl=64 time=0.119 ms
64 bytes from 10.56.217.172: icmp_seq=4 ttl=64 time=0.068 ms

$ oc logs sriov-device-plugin-gbhz2

<Snip> # the logs show the VF is allocated and assigned

I1013 12:31:14.713145       1 server.go:115] Allocate() called with &AllocateRequest{ContainerRequests:[]*ContainerAllocateRequest{&ContainerAllocateRequest{DevicesIDs:[0000:3b:02.4],},},}
I1013 12:31:14.713239       1 netResourcePool.go:50] GetDeviceSpecs(): for devices: [0000:3b:02.4]
I1013 12:31:14.713257       1 pool_stub.go:97] GetEnvs(): for devices: [0000:3b:02.4]
I1013 12:31:14.713264       1 pool_stub.go:113] GetMounts(): for devices: [0000:3b:02.4]
I1013 12:31:14.713270       1 server.go:124] AllocateResponse send: &AllocateResponse{ContainerResponses:[]*ContainerAllocateResponse{&ContainerAllocateResponse{Envs:map[string]string{PCIDEVICE_OPENSHIFT_IO_SRIOV_NETDEVICE_ENS1F0: 0000:3b:02.4,},Mounts:[]*Mount{},Devices:[]*DeviceSpec{},Annotations:map[string]string{},},},}
I1013 12:34:31.240457       1 server.go:115] Allocate() called with &AllocateRequest{ContainerRequests:[]*ContainerAllocateRequest{&ContainerAllocateRequest{DevicesIDs:[0000:3b:02.5],},},}
I1013 12:34:31.240530       1 netResourcePool.go:50] GetDeviceSpecs(): for devices: [0000:3b:02.5]
I1013 12:34:31.240547       1 pool_stub.go:97] GetEnvs(): for devices: [0000:3b:02.5]
I1013 12:34:31.240554       1 pool_stub.go:113] GetMounts(): for devices: [0000:3b:02.5]
I1013 12:34:31.240559       1 server.go:124] AllocateResponse send: &AllocateResponse{ContainerResponses:[]*ContainerAllocateResponse{&ContainerAllocateResponse{Envs:map[string]string{PCIDEVICE_OPENSHIFT_IO_SRIOV_NETDEVICE_ENS1F0: 0000:3b:02.5,},Mounts:[]*Mount{},Devices:[]*DeviceSpec{},Annotations:map[string]string{},},},}

~~~
