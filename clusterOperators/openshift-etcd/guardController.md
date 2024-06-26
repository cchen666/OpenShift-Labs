# Guard Pod

## Guard Controller

<https://github.com/openshift/library-go/blob/master/pkg/operator/staticpod/controller/guard/guard_controller.go>

GuardController is a controller that watches amount of static pods on master nodes and renders guard pods with a pdb to keep maxUnavailable to be at most 1

A PDB and 3 guard Pods will be generated by the controller

```bash

$ oc get pdb etcd-guard-pdb -o yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  creationTimestamp: "2023-08-23T07:58:15Z"
  generation: 1
  name: etcd-guard-pdb
  namespace: openshift-etcd
  resourceVersion: "123565936"
  uid: 314538af-9859-4884-8bb4-d0cc15d94b08
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: guard

$ oc get pods -l app=guard -n openshift-etcd
NAME                                  READY   STATUS    RESTARTS   AGE
etcd-guard-gcg-shift-98bcz-master-0   1/1     Running   2          69d
etcd-guard-gcg-shift-98bcz-master-1   1/1     Running   1          69d
etcd-guard-gcg-shift-98bcz-master-2   1/1     Running   1          69d
```

The etcd-guard Pod only has a readinessProbe to detect port 9980 is healthy or not, where port 9980 is a readyz server started by etcd container

## staticPod Controller

The staticPod Controller will set operandPodLabelSelector label to indicate it needs guard. In the example of etcd, it will use the label etcd=true.

<https://github.com/openshift/cluster-etcd-operator/blob/release-4.12/pkg/operator/starter.go#L241C31-L255>
