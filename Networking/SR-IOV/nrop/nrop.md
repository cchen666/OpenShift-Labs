# Topo Aware Scheduler

Quote from Martin:

```text

The scheduler itself treats all resources as generic pools. The NUMA aware secondary scheduler uses a side channel to get the per-NUMA resource information. The SR-IOV device plugin can expose the topology hints and the Resource topology exporter then can populate the side channel.

+---------------------------------------------------------------------------------+
|                                 CONTROL PLANE                                   |
|                                                                                 |
|       +-------------------+     4. READS NODE      +------------------------+   |
|       |   NUMA-aware      | <-- TOPOLOGY DATA -----|  Topology Info         |   |
|       | Scheduler Plugin  |                        | (via CRD/Annotations)  |   |
|       +--------^----------+                        +------------^-----------+   |
|                | 3. Pod is sent for scheduling                  | 2. POPULATES  |
|                |                                                | "SIDE CHANNEL"|
|       +--------+----------+                                     |               |
|       | kube-scheduler    |                                     |               |
|       +-------------------+                                     |               |
+-----------------------------------------------------------------|---------------+
                                                                  |
                                                                  |
+-----------------------------------------------------------------|---------------+
|                                  WORKER NODE                    |               |
|                                                                 |               |
|                               +---------------------------------+               |
|                               |   Resource Topology Exporter    |               +
|                               +---------------------------------+               |
|                                       ^        ^                                |
|                 1. DISCOVERS          |        | 1. DISCOVERS                   |
|               CPU/MEMORY TOPOLOGY     |        |   DEVICE TOPOLOGY HINTS        |
|                                       |        |                                |
|   +-----------------------+   +-------+--------+-------+   +----------------+   |
|   |  Node CPUs & Memory   |   |   SR-IOV Device Plugin  |   | SR-IOV NIC     |  |
|   |                       |   |                         |   | (Physical)     |  |
|   | [NUMA 0]   [NUMA 1]   |   |   [VF on NUMA 0]        |   |    /      \    |  |
|   |   CPU        CPU      |   |   [VF on NUMA 1]        |   | [VF]      [VF] |  |
|   |   Mem        Mem      |   +-------------------------+   +----------------+  |
|   +-----------------------+                                                     |
|                                                                                 |
+---------------------------------------------------------------------------------+

```

## Install NROP Operator

```bash
$ oc apply -f files/operator.yaml
```

## Create NROP Custom Resource

```bash
$ oc apply -f files/nrop.yaml
```

```bash
$ oc get pods -n openshift-numaresources
NAME                                               READY   STATUS    RESTARTS   AGE
numaresources-controller-manager-fb765f4d4-4lhkc   1/1     Running   0          20m
numaresourcesoperator-worker-numa-f74fj            2/2     Running   0          6m14s
numaresourcesoperator-worker-numa-vvxpt            2/2     Running   0          6m14s
```

## Create topo aware scheduler

```bash
$ oc apply -f files/scheduler.yaml
```

```bash
$ oc get pods -n openshift-numaresources
NAME                                               READY   STATUS    RESTARTS   AGE
numaresources-controller-manager-fb765f4d4-4lhkc   1/1     Running   0          23m
numaresourcesoperator-worker-numa-f74fj            2/2     Running   0          8m39s
numaresourcesoperator-worker-numa-vvxpt            2/2     Running   0          8m39s
secondary-scheduler-b7fd55bff-84n4b                1/1     Running   0          25s
```
