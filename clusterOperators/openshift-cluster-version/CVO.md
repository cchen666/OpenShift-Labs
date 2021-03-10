# Cluster Version Operator

* 1. Operator is usually a pod with Go code running in it. It can either manage sub-component pods' lifecycle including installing, upgrading, or do its own work such as monitoring.

* 2. Cluster Version Operator (CVO) generates cluster-wide operator called `cluster operator`. CVO is created or injected by the installer when the control plane was created.

* 3. Speaking of the installer, the installer firstly create a one-node etcd cluster, then after masters are provisioned, the master nodes join the etcd cluster with totally 4 nodes, and kicks the installer out to form a 3 node etcd cluster. Installer then injects (copy) the containers metadata (mainly yaml files) to the masters and masters create necessary resources based on the yaml files during which CVO is created.

* 4. CVO monitors whether there is any update for the cluster operators.

* 5. If you want to rebuild the operator, you need to set `unmanaged` in ClusterVersion.

* 6. An example of rebuilding the operator <https://docs.google.com/document/d/1RUUVkj0Pa2xdAazghh0ghMXfLY4L28pKejTMecFdq1k/edit>

## Get ClusterVersion and release-image

~~~bash
$ oc get clusterversion version -o yaml | grep desired -A 10
$ oc get clusterversion -o jsonpath='{.status.desired.image}{"\n"}' version

VER=$(oc get clusterversion version -o jsonpath='{.status.desired.image}')
$ oc adm release extract --from=$VER --to=release-image

$ ls release-image/*samples*
~~~

## Order of upgrade which is manifests from `release-image`

~~~bash
$ oc project openshift-cluster-version
$ oc get pods

#### CVO's own manifest

sh-4.4# ls -l manifests/
total 60
-rw-r--r--. 1 root root   319 Apr 15 14:56 0000_00_cluster-version-operator_00_namespace.yaml
-rw-r--r--. 1 root root  6944 Apr 15 14:56 0000_00_cluster-version-operator_01_clusteroperator.crd.yaml
-rw-r--r--. 1 root root 16428 Apr 15 14:56 0000_00_cluster-version-operator_01_clusterversion.crd.yaml
-rw-r--r--. 1 root root   335 Apr 15 14:56 0000_00_cluster-version-operator_02_roles.yaml
-rw-r--r--. 1 root root  3201 Apr 15 14:56 0000_00_cluster-version-operator_03_deployment.yaml
-rw-r--r--. 1 root root   323 Apr 15 14:56 0000_90_cluster-version-operator_00_prometheusrole.yaml
-rw-r--r--. 1 root root   458 Apr 15 14:56 0000_90_cluster-version-operator_01_prometheusrolebinding.yaml
-rw-r--r--. 1 root root  5263 Apr 15 14:56 0000_90_cluster-version-operator_02_servicemonitor.yaml
-rw-r--r--. 1 root root   565 Apr 15 14:56 0001_00_cluster-version-operator_03_service.yaml

# Other CO's manifests which will be applied in graphical order. This is retrieved from `release-image`

sh-4.4# ls -l release-manifests/ | head -n 10
total 4968
-r--r--r--. 1 root root  10339 Apr 15 14:34 0000_03_authorization-openshift_01_rolebindingrestriction.crd.yaml
-r--r--r--. 1 root root   4636 Apr 15 14:34 0000_03_config-operator_01_operatorhub.crd.yaml
-r--r--r--. 1 root root   4655 Apr 15 14:34 0000_03_config-operator_01_proxy.crd.yaml
-r--r--r--. 1 root root  11863 Apr 15 14:34 0000_03_quota-openshift_01_clusterresourcequota.crd.yaml
-r--r--r--. 1 root root  15573 Apr 15 14:34 0000_03_security-openshift_01_scc.crd.yaml
-r--r--r--. 1 root root   1990 Apr 15 14:34 0000_03_securityinternal-openshift_02_rangeallocation.crd.yaml
-r--r--r--. 1 root root    338 Apr 15 14:34 0000_05_config-operator_02_apiserver.cr.yaml
-r--r--r--. 1 root root    151 Apr 15 14:34 0000_05_config-operator_02_authentication.cr.yaml
-r--r--r--. 1 root root    142 Apr 15 14:34 0000_05_config-operator_02_build.cr.yaml

~~~

## Update graphical lab

<https://access.redhat.com/labs/ocpupgradegraph/update_channel>
