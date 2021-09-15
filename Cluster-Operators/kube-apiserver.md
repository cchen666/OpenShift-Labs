## Get current revision

~~~bash
$ oc get kubeapiserver -o=jsonpath='{range .items[0].status.conditions[?(@.type=="NodeInstallerProgressing")]}{.reason}{"\n"}{.message}{"\n"}'

Updating:

1 nodes are at revision 19; 0 nodes have achieved new revision 20
Update Done:

AllNodesAtLatestRevision
1 nodes are at revision 20
~~~
## Customize audit logging

* [KCS](https://access.redhat.com/solutions/5373481)

* [k8s official docs](https://kubernetes.io/docs/tasks/debug-application-cluster/audit/)

