# Offline Migration from SDN to OVN Checklist

## Step 1: Check COs

## Step 2: Makes sure migration field is null

```bash
$ oc patch Network.operator.openshift.io cluster --type='merge' \
--patch '{"spec":{"migration":null}}'
```

## Step 3: Set migration field to ovn

```bash
$ oc patch Network.operator.openshift.io cluster --type='merge' \
--patch '{ "spec": { "migration": { "networkType": "OVNKubernetes" } } }'
```

Check the status of the network.config, the migration shows networkType=OVNKubernetes and networkType=OpenShiftSDN.

```bash
$ oc get network.config/cluster -o yaml
status:
  clusterNetwork:
  - cidr: 10.128.0.0/20
    hostPrefix: 23
  clusterNetworkMTU: 1450
  conditions:
  - lastTransitionTime: "2026-03-31T10:00:00Z"
    message: ""
    reason: AsExpected
    status: "True"
    type: NetworkDiagnosticsAvailable
  migration:
    networkType: OVNKubernetes
  networkType: OpenShiftSDN
```

Check the CRDs

```bash
$ oc get crd | grep ovn
adminpolicybasedexternalroutes.k8s.ovn.org                        2026-04-01T03:25:48Z
egressfirewalls.k8s.ovn.org                                       2026-04-01T03:25:47Z
egressips.k8s.ovn.org                                             2026-04-01T03:25:47Z
egressqoses.k8s.ovn.org                                           2026-04-01T03:25:48Z
egressservices.k8s.ovn.org                                        2026-04-01T03:25:48Z
```

Check the node has br-ex now, coexisting with br0:

```bash
# ovs-vsctl show
a4784fce-3f91-4fb2-b8ce-ba2f57d95989
    Bridge br0
        fail_mode: secure
        Port tun0
            Interface tun0
                type: internal
        Port br0
            Interface br0
                type: internal
        Port veth41a885dd
            Interface veth41a885dd
        Port vxlan0
            Interface vxlan0
                type: vxlan
                options: {dst_port="4789", key=flow, remote_ip=flow}
        Port veth749baad8
            Interface veth749baad8
    Bridge br-ex
        Port br-ex
            Interface br-ex
                type: internal
        Port enp1s0
            Interface enp1s0
                type: system
    ovs_version: "3.3.6-141.el9fdp"
```

Check sdn Pods still exist while ovn Pods are not running:

```bash
$ oc get pods -n openshift-sdn
NAME                   READY   STATUS    RESTARTS   AGE
sdn-6skh4              2/2     Running   2          16m
sdn-controller-gdzf9   2/2     Running   4          18h
sdn-d8t27              2/2     Running   0          16m
sdn-ldjcd              2/2     Running   4          18h
$ oc get pods -n openshift-ovn-kubernetes
No resources found in openshift-ovn-kubernetes namespace.
```

Check the routing table now for default gateway which points to br-ex:

```bash
$ ip route
default via 172.16.0.1 dev br-ex proto dhcp src 172.16.0.101 metric 48
10.128.0.0/20 dev tun0 scope link
172.16.0.0/24 dev br-ex proto kernel scope link src 172.16.0.101 metric 48
172.30.0.0/16 dev tun0
```

Summary for step 3:

### Command

```bash
$ oc patch Network.operator.openshift.io cluster --type='merge' \
--patch '{"spec":{"migration":{"networkType":"OVNKubernetes"}}}'
```

### What Happens

- CNO deploys OVN CRDs
- CNO propagates migration target to network.config status
- MCO generates new MachineConfig with configure-ovs.sh OVNKubernetes
- Nodes reboot (1st round) — br-ex created, physical NIC moved into br-ex
- SDN continues operating normally (br0 is independent of br-ex)

## Step 4: Migrate

```bash
$ oc patch Network.config.openshift.io cluster --type='merge' \
--patch '{ "spec": { "networkType": "OVNKubernetes" } }'
```

Check the ovn Pods are being generated:

```bash
$ oc get ds -n openshift-ovn-kubernetes
NAME           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
ovnkube-node   3         3         3       3            3           kubernetes.io/os=linux   4m40s

$ oc get pods -n openshift-ovn-kubernetes
NAME                                    READY   STATUS    RESTARTS   AGE
ovnkube-control-plane-fb6659bd4-h77d9   2/2     Running   0          4m31s
ovnkube-node-285cp                      8/8     Running   0          4m1s
ovnkube-node-gglcz                      8/8     Running   0          83s
ovnkube-node-mcwb4                      8/8     Running   0          82s
```

Check sdn Pods are gone:

```bash
$ oc get pods -n openshift-sdn
No resources found in openshift-sdn namespace.
```

Check multus Pods rollout, including the new configMap and the Pods restarts:

```bash
$ oc get cm -n openshift-multus multus-daemon-config -o yaml
apiVersion: v1
data:
  daemon-config.json: |
    {
        "cniVersion": "0.3.1",
        "chrootDir": "/hostroot",
        "logToStderr": true,
        "logLevel": "verbose",
        "binDir": "/var/lib/cni/bin",

        "perNodeCertificate": {
          "enabled": true,
          "bootstrapKubeconfig": "/var/lib/kubelet/kubeconfig",
          "certDir": "/etc/cni/multus/certs",
          "certDuration": "24h"
        },

        "cniConfigDir": "/host/etc/cni/net.d",
        "multusConfigFile": "auto",
        "multusAutoconfigDir": "/host/run/multus/cni/net.d",
        "namespaceIsolation": true,
        "globalNamespaces": "default,openshift-multus,openshift-sriov-network-operator",
        "readinessindicatorfile": "/host/run/multus/cni/net.d/10-ovn-kubernetes.conf",  <-- NOTE
        "daemonSocketDir": "/run/multus/socket",
        "socketDir": "/host/run/multus/socket"
    }
kind: ConfigMap

$ oc -n openshift-multus get pods
NAME                                          READY   STATUS    RESTARTS        AGE
multus-additional-cni-plugins-7mklq           1/1     Running   1               5h24m
multus-additional-cni-plugins-p9rxj           1/1     Running   1               5h23m
multus-additional-cni-plugins-wmbzs           1/1     Running   2               23h
multus-admission-controller-89b7fc7cf-sktpr   2/2     Running   4               23h
multus-sfzhr                                  1/1     Running   6 (3m59s ago)   23h
multus-vjcm2                                  1/1     Running   5 (4m15s ago)   5h23m
multus-wmj8f                                  1/1     Running   5 (4m18s ago)   5h24m
network-metrics-daemon-6bbl4                  2/2     Running   4               23h
network-metrics-daemon-rhknc                  2/2     Running   2               5h23m
network-metrics-daemon-zxlsl                  2/2     Running   2               5h24m

$ oc -n openshift-multus rollout status daemonset/multus
daemon set "multus" successfully rolled out

# On worker nodes
$ grep 10-ovn-kubernetes.conf /etc/kubernetes/ -r
/etc/kubernetes/cni/net.d/00-multus.conf:{"binDir":"/var/lib/cni/bin","cniVersion":"0.3.1","logLevel":"verbose","logToStderr":true,"name":"multus-cni-network","clusterNetwork":"/host/run/multus/cni/net.d/10-ovn-kubernetes.conf","namespaceIsolation":true,"globalNamespaces":"default,openshift-multus,openshift-sriov-network-operator","type":"multus-shim","daemonSocketDir":"/run/multus/socket"}
```

Check current ovs bridges and ports on one of the workers:

```bash
$ ovs-vsctl show
7d34280d-ac4e-4914-b488-7b2bb9d02bf7
    Bridge br-int
        fail_mode: secure
        datapath_type: system
        Port br-int
            Interface br-int
                type: internal
        Port ovn-k8s-mp0
            Interface ovn-k8s-mp0
                type: internal
        Port ovn-5af45e-0
            Interface ovn-5af45e-0
                type: geneve
                options: {csum="true", key=flow, local_ip="172.16.0.104", remote_ip="172.16.0.101"}
        Port ovn-e7fb04-0
            Interface ovn-e7fb04-0
                type: geneve
                options: {csum="true", key=flow, local_ip="172.16.0.104", remote_ip="172.16.0.105"}
        Port patch-br-int-to-br-ex_worker-0
            Interface patch-br-int-to-br-ex_worker-0
                type: patch
                options: {peer=patch-br-ex_worker-0-to-br-int}
    Bridge br0
        fail_mode: secure
        Port vethf5b30f76
            Interface vethf5b30f76
        Port vethb6dfd9f6
            Interface vethb6dfd9f6
        Port tun0
            Interface tun0
                type: internal
        Port vxlan0
            Interface vxlan0
                type: vxlan
                options: {dst_port="4789", key=flow, remote_ip=flow}
        Port veth256e256f
            Interface veth256e256f
        Port vethbd93a1de
            Interface vethbd93a1de
        Port br0
            Interface br0
                type: internal
    Bridge br-ex
        Port patch-br-ex_worker-0-to-br-int
            Interface patch-br-ex_worker-0-to-br-int
                type: patch
                options: {peer=patch-br-int-to-br-ex_worker-0}
        Port enp1s0
            Interface enp1s0
                type: system
        Port br-ex
            Interface br-ex
                type: internal
    ovs_version: "3.3.6-141.el9fdp"
```

If I delete one of the Pod on this worker. After the new Pod is spawned, br0 remains the same and br-ex increases. This is because sdn Pods are gone and cmdDel() is never called by sdn CNI.

```bash
$ ovs-vsctl show
7d34280d-ac4e-4914-b488-7b2bb9d02bf7
    Bridge br-int
        fail_mode: secure
        datapath_type: system
        Port br-int
            Interface br-int
                type: internal
        Port "67b5fe432a04acc"
            Interface "67b5fe432a04acc"
        Port ovn-k8s-mp0
            Interface ovn-k8s-mp0
                type: internal
        Port "42ef1ecd7aa867c"
            Interface "42ef1ecd7aa867c"
        Port ovn-5af45e-0
            Interface ovn-5af45e-0
                type: geneve
                options: {csum="true", key=flow, local_ip="172.16.0.104", remote_ip="172.16.0.101"}
        Port ovn-e7fb04-0
            Interface ovn-e7fb04-0
                type: geneve
                options: {csum="true", key=flow, local_ip="172.16.0.104", remote_ip="172.16.0.105"}
        Port patch-br-int-to-br-ex_worker-0
            Interface patch-br-int-to-br-ex_worker-0
                type: patch
                options: {peer=patch-br-ex_worker-0-to-br-int}
    Bridge br0
        fail_mode: secure
        Port vethf5b30f76
            Interface vethf5b30f76
                error: "could not open network device vethf5b30f76 (No such device)"
        Port vethb6dfd9f6
            Interface vethb6dfd9f6
        Port tun0
            Interface tun0
                type: internal
        Port vxlan0
            Interface vxlan0
                type: vxlan
                options: {dst_port="4789", key=flow, remote_ip=flow}
        Port veth256e256f
            Interface veth256e256f
        Port vethbd93a1de
            Interface vethbd93a1de
        Port br0
            Interface br0
                type: internal
    Bridge br-ex
        Port patch-br-ex_worker-0-to-br-int
            Interface patch-br-ex_worker-0-to-br-int
                type: patch
                options: {peer=patch-br-int-to-br-ex_worker-0}
        Port enp1s0
            Interface enp1s0
                type: system
        Port br-ex
            Interface br-ex
                type: internal
    ovs_version: "3.3.6-141.el9fdp"
```

Check ovn-k CNI conf is created on the nodes

```bash
$ ls /run/multus/cni/net.d/10-ovn-kubernetes.conf
/run/multus/cni/net.d/10-ovn-kubernetes.conf
```

At this moment no MC is created.

```bash
oc get mc
NAME                                               GENERATEDBYCONTROLLER                      IGNITIONVERSION   AGE
00-master                                          67c9ad546b13e9f04f96524c8bbbb405725b7d61   3.4.0             27h
00-worker                                          67c9ad546b13e9f04f96524c8bbbb405725b7d61   3.4.0             27h
01-master-container-runtime                        67c9ad546b13e9f04f96524c8bbbb405725b7d61   3.4.0             27h
01-master-kubelet                                  67c9ad546b13e9f04f96524c8bbbb405725b7d61   3.4.0             27h
01-worker-container-runtime                        67c9ad546b13e9f04f96524c8bbbb405725b7d61   3.4.0             27h
01-worker-kubelet                                  67c9ad546b13e9f04f96524c8bbbb405725b7d61   3.4.0             27h
97-master-generated-kubelet                        67c9ad546b13e9f04f96524c8bbbb405725b7d61   3.4.0             23h
97-worker-generated-kubelet                        67c9ad546b13e9f04f96524c8bbbb405725b7d61   3.4.0             23h
98-master-generated-kubelet                        67c9ad546b13e9f04f96524c8bbbb405725b7d61   3.4.0             27h
98-worker-generated-kubelet                        67c9ad546b13e9f04f96524c8bbbb405725b7d61   3.4.0             27h
99-master-generated-registries                     67c9ad546b13e9f04f96524c8bbbb405725b7d61   3.4.0             27h
99-master-ssh                                                                                 3.2.0             28h
99-worker-generated-registries                     67c9ad546b13e9f04f96524c8bbbb405725b7d61   3.4.0             27h
99-worker-ssh                                                                                 3.2.0             28h
rendered-master-1c53308438d21df769bbd59a4dd5a782   b23bb29eeffa659058ae6a88969cc0e6a97d82f5   3.4.0             24h
rendered-master-6d583f834bfbb69f4dbf58d19f0960ab   67c9ad546b13e9f04f96524c8bbbb405725b7d61   3.4.0             23h
rendered-master-a51222dbaeb8849565d36e59d2fe2a6f   67c9ad546b13e9f04f96524c8bbbb405725b7d61   3.4.0             5h37m
rendered-master-c0e1c8fa37b2f3b582ae47b78485d28b   4f8b6f2a0e1a8ec475e5ef1dd8effd9306804518   3.4.0             27h
rendered-master-d98970da34551d3bb00b1e69ad727791   4f8b6f2a0e1a8ec475e5ef1dd8effd9306804518   3.4.0             27h
rendered-worker-2b76ef7aaf1e590d8aea8554f231208b   67c9ad546b13e9f04f96524c8bbbb405725b7d61   3.4.0             5h37m
rendered-worker-5499d2babeceaa0cad6534449635cd08   4f8b6f2a0e1a8ec475e5ef1dd8effd9306804518   3.4.0             27h
rendered-worker-58092f4223bb23cea331bc8001fc448b   67c9ad546b13e9f04f96524c8bbbb405725b7d61   3.4.0             23h
rendered-worker-8ca5643ce53900f0802a574ee95fa11d   b23bb29eeffa659058ae6a88969cc0e6a97d82f5   3.4.0             24h
rendered-worker-c2213c3d939fde5107c8457c62a49134   4f8b6f2a0e1a8ec475e5ef1dd8effd9306804518   3.4.0             27h
```

Check network.config and network.operator CR status:

```bash
$ oc get network.config -o yaml
apiVersion: config.openshift.io/v1
kind: Network
metadata:
  creationTimestamp: "2026-03-31T04:52:23Z"
  generation: 7
  name: cluster
  resourceVersion: "308372"
  uid: c4308548-ef79-4b53-bcfa-dfb38bf7900f
spec:
  clusterNetwork:
  - cidr: 10.128.0.0/20
    hostPrefix: 23
  externalIP:
    policy: {}
  networkType: OVNKubernetes
  serviceNetwork:
  - 172.30.0.0/16
status:
  clusterNetwork:
  - cidr: 10.128.0.0/20
    hostPrefix: 23
  clusterNetworkMTU: 1400
  conditions:
  - lastTransitionTime: "2026-04-01T03:36:52Z"
    message: ""
    reason: AsExpected
    status: "True"
    type: NetworkDiagnosticsAvailable
  migration:
    networkType: OVNKubernetes
  networkType: OVNKubernetes
  serviceNetwork:
  - 172.30.0.0/16

$ oc get network.operator cluster -o yaml
apiVersion: operator.openshift.io/v1
kind: Network
metadata:
  creationTimestamp: "2026-03-31T05:03:14Z"
  generation: 155
  name: cluster
  resourceVersion: "310059"
  uid: 91857d62-09f4-499f-8929-eb552860f227
spec:
  clusterNetwork:
  - cidr: 10.128.0.0/20
    hostPrefix: 23
  defaultNetwork:
    ovnKubernetesConfig:
      egressIPConfig: {}
      gatewayConfig:
        ipv4: {}
        ipv6: {}
        routingViaHost: false
      genevePort: 6081
      ipsecConfig:
        mode: Disabled
      mtu: 1400
      policyAuditConfig:
        destination: "null"
        maxFileSize: 50
        maxLogFiles: 5
        rateLimit: 20
        syslogFacility: local0
    type: OVNKubernetes
  deployKubeProxy: false
  disableMultiNetwork: false
  disableNetworkDiagnostics: false
  kubeProxyConfig:
    bindAddress: 0.0.0.0
  logLevel: Normal
  managementState: Managed
  migration:
    networkType: OVNKubernetes
  observedConfig: null
  operatorLogLevel: Normal
  serviceNetwork:
  - 172.30.0.0/16
  unsupportedConfigOverrides: null
  useMultiNetworkPolicy: false
status:
  conditions:
  - lastTransitionTime: "2026-03-31T05:03:14Z"
    message: ""
    reason: ""
    status: "False"
    type: ManagementStateDegraded
  - lastTransitionTime: "2026-04-01T09:01:43Z"
    message: ""
    reason: ""
    status: "False"
    type: Degraded
  - lastTransitionTime: "2026-04-01T08:57:29Z"
    message: ""
    reason: ""
    status: "True"
    type: Upgradeable
  - lastTransitionTime: "2026-04-01T09:01:42Z"
    message: ""
    reason: ""
    status: "False"
    type: Progressing
  - lastTransitionTime: "2026-03-31T05:06:11Z"
    message: ""
    reason: ""
    status: "True"
    type: Available
  readyReplicas: 0
  version: 4.16.55
```

Check feature migration status:

If the source SDN cluster had any of these features, you should verify the migration objects were created:

- EgressNetworkPolicy → EgressFirewall: `oc get egressfirewall -A`
- Multicast annotations → MulticastEnabled annotation: Check namespace annotations
- EgressIP (HostSubnet) → EgressIP (OVN): `oc get egressip -A`

### Summary

#### Command

```bash
$ oc patch Network.config.openshift.io cluster --type='merge' \
--patch '{ "spec": { "networkType": "OVNKubernetes" } }'
```

#### What Happens

- CNO renders OVN DaemonSets/ConfigMaps for ovnk Pods
- StatusManager detects SDN DaemonSets are no longer in rendered objects → explicitly deletes them via deleteRelatedObjectsNotRendered()
- Feature migration fires (operconfig_controller.go:564): EgressNetworkPolicy→EgressFirewall, Multicast annotations, EgressIP conversion (no-op if
  features unused)
- Multus ConfigMap reapplied (already points to 10-ovn-kubernetes.conf from step 1) → Multus DaemonSet re-rolls out
- network.config status.networkType = OVNKubernetes, status.migration still present
- No new MachineConfig — status.migration.networkType unchanged from step 1, so MCO has nothing new to render
- No node reboots — nodes must be manually rebooted after this step
- New pods get veth on br-int (OVN); deleted pods leave stale veths on br0 (SDN cmdDel never called)
- br0 persists as stale artifact until manual node reboot cleans it up

## Step 5: Reboot

### What the reboot fixes

When you reboot a node:

- All existing pods on that node are terminated and rescheduled
- Rescheduled pods get OVN networking (veth → br-int)
- br0 is not recreated — stale bridge and its artifacts are cleaned up
- configure-ovs.sh OVNKubernetes runs, confirms br-ex setup
