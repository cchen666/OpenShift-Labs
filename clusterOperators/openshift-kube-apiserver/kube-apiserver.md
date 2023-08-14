# kube-apiserver

## Get current revision

```bash
$ oc get kubeapiserver -o=jsonpath='{range .items[0].status.conditions[?(@.type=="NodeInstallerProgressing")]}{.reason}{"\n"}{.message}{"\n"}'

Updating:

1 nodes are at revision 19; 0 nodes have achieved new revision 20
Update Done:

AllNodesAtLatestRevision
1 nodes are at revision 20
```

## Customize audit logging

* [KCS](https://access.redhat.com/solutions/5373481)

* [k8s official docs](https://kubernetes.io/docs/tasks/debug-application-cluster/audit/)

## API Priority and Fairness

<https://kubernetes.io/zh/docs/concepts/cluster-administration/flow-control/>
<https://blog.csdn.net/sinat_37367944/article/details/116329588>

```bash

$ oc get --raw /debug/api_priority_and_fairness/dump_priority_levels
PriorityLevelName,                 ActiveQueues, IsIdle, IsQuiescing, WaitingRequests, ExecutingRequests
exempt,                            <none>,       <none>, <none>,      <none>,          <none>
global-default,                    0,            false,  false,       0,               1
leader-election,                   0,            true,   false,       0,               0
openshift-control-plane-operators, 0,            true,   false,       0,               0
system,                            0,            true,   false,       0,               0
workload-high,                     0,            false,  false,       0,               5
workload-low,                      0,            false,  false,       0,               10
catch-all,                         0,            true,   false,       0,               0

$ oc get PriorityLevelConfigurations
NAME                                TYPE      ASSUREDCONCURRENCYSHARES   QUEUES   HANDSIZE   QUEUELENGTHLIMIT   AGE
catch-all                           Limited   5                          <none>   <none>     <none>             26d
exempt                              Exempt    <none>                     <none>   <none>     <none>             26d
global-default                      Limited   20                         128      6          50                 26d
leader-election                     Limited   10                         16       4          50                 26d
openshift-control-plane-operators   Limited   10                         128      6          50                 26d
system                              Limited   30                         64       6          50                 26d
workload-high                       Limited   40                         128      6          50                 26d
workload-low                        Limited   100                        128      6          50                 26d$

```
