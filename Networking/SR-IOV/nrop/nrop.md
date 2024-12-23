# Topo Aware Scheduler

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
