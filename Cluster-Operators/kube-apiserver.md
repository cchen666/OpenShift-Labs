#### Get current revision
~~~
# oc get kubeapiserver -o=jsonpath='{range .items[0].status.conditions[?(@.type=="NodeInstallerProgressing")]}{.reason}{"\n"}{.message}{"\n"}'

Updating:

1 nodes are at revision 19; 0 nodes have achieved new revision 20
Update Done:

AllNodesAtLatestRevision
1 nodes are at revision 20
~~~
#### Customize audit logging
~~~
https://access.redhat.com/solutions/5373481
https://kubernetes.io/docs/tasks/debug-application-cluster/audit/
~~~
