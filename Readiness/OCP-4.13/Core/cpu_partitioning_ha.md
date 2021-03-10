# Configure CPU(Workload) Paritioning Feature (WPF) on Multi-node Cluster

## Configure install-config.yaml

TLDR: This feature can only be configured in day1 (installation phase)
This is an install time only feature, there is no leaver presented to customers to turn on this feature after install time. This feature is also enabled on the whole cluster. This is also not intended to be something that you turn off after install either. Once it is on, it is on for the entire life of the cluster. This is done to guarantee behavior of the pods as it relates to scheduling and resource usage. In the future this might change, but for this implementation the intent is to be on from the start if desired.


```yaml
apiVersion: v1
baseDomain: devcluster.openshift.com
# New Addition
cpuPartitioningMode: AllNodes # default is None
compute:
 - architecture: amd64
   hyperthreading: Enabled
   name: worker
   platform: {}
   replicas: 3
controlPlane:
 architecture: amd64
 hyperthreading: Enabled
 name: master
 platform: {}
 replicas: 3
```

## Create pao.yaml and Apply

```yaml

apiVersion: performance.openshift.io/v2
kind: PerformanceProfile
metadata:
 name: openshift-node-workload-partitioning-worker
spec:
 cpu:
   isolated: 0,1
   reserved: "2-3" # Will now drive configurations
 machineConfigPoolSelector:
   pools.operator.machineconfiguration.openshift.io/worker: ""
 nodeSelector:
   node-role.kubernetes.io/worker: ""

```

## Check CPU affinity for each Management Workload Pod

## Caveats

1. Nodes that are not configured for partitioning, can not join the cluster
2. Machine configuration pools can not contain nodes of mixed CPU sizes, they must be all of one size
3. The `request` of CPU will become annotations

```bash
$ oc describe node
<snip>
  Namespace                                         Name                                                                          CPU Requests
  ---------                                         ----                                                                          ------------
  openshift-apiserver-operator                      openshift-apiserver-operator-68bfcb9bdc-2hnkh                                 0 (0%)
  openshift-apiserver                               apiserver-5c4f68c858-cp8bc                                                    0 (0%)
  openshift-authentication-operator                 authentication-operator-764d5cb9c8-h9stb                                      0 (0%)
  openshift-authentication                          oauth-openshift-7d6f5f959-dpks5                                               0 (0%)
  openshift-cloud-credential-operator               cloud-credential-operator-656f9bf484-x7gmp                                    0 (0%)
  openshift-cluster-machine-approver                machine-approver-6bcc7c8df-9xdgq                                              0 (0%)
  openshift-cluster-node-tuning-operator            cluster-node-tuning-operator-79fc4c8d67-9v9p4                                 0 (0%)
  openshift-cluster-node-tuning-operator            tuned-24z9k                                                                   0 (0%)
  openshift-cluster-samples-operator                cluster-samples-operator-6fd48dd67d-2mhwt                                     0 (0%)
  openshift-cluster-storage-operator                cluster-storage-operator-bbc946fd8-vbzvq                                      0 (0%)
  openshift-cluster-version                         cluster-version-operator-57bdd4c9d4-x2fbw                                     0 (0%)
  openshift-config-operator                         openshift-config-operator-7885868bdc-ghxlh                                    0 (0%)

```

```bash
$ oc describe pod openshift-apiserver-operator-68bfcb9bdc-2hnkh -n openshift-apiserver-operator
Annotations:
                      resources.workload.openshift.io/openshift-apiserver-operator: {"cpushares": 10}
                      target.workload.openshift.io/management: {"effect":"PreferredDuringScheduling"}
    Limits:
      management.workload.openshift.io/cores:  10
    Requests:
      management.workload.openshift.io/cores:  10
      memory:                                  50Mi

```
