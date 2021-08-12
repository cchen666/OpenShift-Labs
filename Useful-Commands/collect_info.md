oc adm inspect $(oc get co -o name) clusterversion/version ns/openshift-cluster-version $(oc get node -o name) ns/default ns/openshift ns/kube-system ns/openshift-etcd
