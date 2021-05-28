#### An interface to configure kubelet for MCO.
https://github.com/openshift/machine-config-operator/blob/master/docs/KubeletConfigDesign.md
#### The MCO upstream docs
https://github.com/openshift/machine-config-operator/tree/master/docs
#### Troubleshooting
* 1. Which node is failing the upgrade
~~~
# Check the operator state
cluster-scoped-resources/config.openshift.io/clusteroperators/machine-config.yaml

# Check current rendered id

grep -i render cluster-scoped-resources/machineconfiguration.openshift.io/machineconfigpools/worker.yaml

for i in `nodes`; do cat cluster-scoped-resources/core/nodes/ | grep -i render; done
~~~

~~~
# Locate the problemtaic node

namespaces/openshift-machine-config-operator/pods/machine-config-daemon*/logs/

namespaces/openshift-machine-config-operator/pods/machine-config-controller/logs/
~~~

* 2. OMG COMMAND
~~~
# collabshell
# omg use <quay-io-openshift-release-dev-ocp-v4.0-xxxxxxx>
# omg get pods
~~~
* 3. Check why nodes get rebooted
~~~
1. Locate machine-config-daemon log
2. Search "Starting update from" keywords in MCD logs
3. oc get mc rendered-old > old.yaml
   oc get mc rendered-new > new.yaml
   diff old.yaml new.yaml
Case #02883889
~~~
