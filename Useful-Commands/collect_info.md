# Collect Info

## Namespaces

~~~bash
oc adm inspect $(oc get co -o name) clusterversion/version ns/openshift-cluster-version $(oc get node -o name) ns/default ns/openshift ns/kube-system ns/openshift-etcd
~~~


## Alternative method

~~~bash
gathering data via script Instead, create and execute the following script:

cat <<'EOF' > collect-sriov-operator-data.sh
#!/bin/bash 

NAMESPACE=openshift-sriov-network-operator

echo "=== Overview ===" 

oc get pods -n $NAMESPACE
oc get deployments -n $NAMESPACE
oc get replicasets -n $NAMESPACE
oc get daemonsets -n $NAMESPACE

oc get csv -n $NAMESPACE
oc get operatorgroup -n $NAMESPACE

oc get SriovOperatorConfig -n $NAMESPACE
oc get SriovNetwork -n $NAMESPACE
oc get SriovNetworkNodeState -n $NAMESPACE
oc get SriovNetworkNodePolicy -n $NAMESPACE

echo "=== -o yaml ==="

oc get -o yaml pods -n $NAMESPACE
oc get -o yaml deployments -n $NAMESPACE
oc get -o yaml replicasets -n $NAMESPACE
oc get -o yaml daemonsets -n $NAMESPACE

oc get -o yaml csv -n $NAMESPACE
oc get -o yaml operatorgroup -n $NAMESPACE

oc get -o yaml SriovOperatorConfig -n $NAMESPACE
oc get -o yaml SriovNetwork -n $NAMESPACE
oc get -o yaml SriovNetworkNodeState -n $NAMESPACE
oc get -o yaml SriovNetworkNodePolicy -n $NAMESPACE

echo "=== describe ==="

oc describe pods -n $NAMESPACE
oc describe deployments -n $NAMESPACE
oc describe replicasets -n $NAMESPACE
oc describe daemonsets -n $NAMESPACE

oc describe csv -n $NAMESPACE
oc describe operatorgroup -n $NAMESPACE

oc describe SriovOperatorConfig -n $NAMESPACE
oc describe SriovNetwork -n $NAMESPACE
oc describe SriovNetworkNodeState -n $NAMESPACE
oc describe SriovNetworkNodePolicy -n $NAMESPACE

echo "=== Collecting node info ==="
oc get nodes -o yaml

echo "=== Collecting logs ==="
for pod in $(oc get pods -n $NAMESPACE -o name); do 
  echo "+++ logs for pod $pod +++"
  oc logs -n $NAMESPACE $pod
done

EOF
bash collect-sriov-operator-data.sh | tee collect-sriov-operator-data.txt
~~~