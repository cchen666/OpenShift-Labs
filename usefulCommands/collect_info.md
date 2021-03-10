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

## Quick method to collect sosreport

<https://gitlab.cee.redhat.com/-/snippets/4308>

sos pod yaml

~~~ yaml
apiVersion: v1
kind: Pod
metadata:
  name: sos-collector
  labels:
    name: sosreport-container
spec:
  hostNetwork: true
  nodeName: "NODE NAME"   ## TODO: Template or Change
  hostPID: true
  restartPolicy: Never
  priorityClassName: "system-cluster-critical"
  tolerations:
  - key: node-role.kubernetes.io/master
    operator: "Equal"
    effect: "NoExecute"
    tolerationSeconds: 3600
  - key: node-role.kubernetes.io/master
    operator: "Equal"
    effect: "NoSchedule"
  containers:
  - name: sos-extractor
    image: registry.redhat.io/rhel8/support-tools
    command: ["/bin/bash", "-c", "trap : TERM INT; sleep infinity & wait"]
    volumeMounts:
    - mountPath: /tmp/sos-data
      name: sos-data
  initContainers:
  - name: sos-collector
    image: registry.redhat.io/rhel8/support-tools
    command: ["sosreport", "-s", "/host", "--tmp-dir", "/tmp/sos-data", "-c", "always", "--batch", "-v"]
    securityContext:
      runAsUser: 0
      privileged: True
    volumeMounts:
    - mountPath: /host
      name: host-volume
    - mountPath: /tmp/sos-data
      name: sos-data
  volumes:
  - name: host-volume
    hostPath:
      path: /
      type: Directory
  - name: sos-data
    emptyDir: {}
~~~

sos pod template yaml

~~~ yaml
apiVersion: v1
kind: Template
metadata:
  name: sosreport-template
  annotations:
    description: "Description"
    iconClass: "life-ring"
    tags: "support-tool,sosreport"
objects:
- apiVersion: v1
  kind: Pod
  metadata:
    name: sos-collector
    labels:
      name: sosreport-container
  spec:
    hostNetwork: true
    nodeName: ${NODE_NAME}
    hostPID: true
    restartPolicy: Never
    priorityClassName: "system-cluster-critical"
    tolerations:
    - key: node-role.kubernetes.io/master
      operator: "Equal"
      effect: "NoExecute"
      tolerationSeconds: 3600
    - key: node-role.kubernetes.io/master
      operator: "Equal"
      effect: "NoSchedule"
    containers:
    - name: sos-extractor
      image: registry.redhat.io/rhel8/support-tools
      command: ["/bin/bash", "-c", "trap : TERM INT; sleep infinity & wait"]
      volumeMounts:
      - mountPath: /tmp/sos-data
        name: sos-data
    initContainers:
    - name: sos-collector
      image: registry.redhat.io/rhel8/support-tools
      command: ["sosreport", "-s", "/host", "--tmp-dir", "/tmp/sos-data", "-c", "always", "--batch", "-v"]
      securityContext:
        runAsUser: 0
        privileged: True
      volumeMounts:
      - mountPath: /host
        name: host-volume
      - mountPath: /tmp/sos-data
        name: sos-data
    volumes:
    - name: host-volume
      hostPath:
        path: /
        type: Directory
    - name: sos-data
      emptyDir: {}
parameters:
- description: "Node Name to collect the sosreport on."
  name: NODE_NAME
  required: true
~~~

~~~bash
$ oc get template
NAME                 DESCRIPTION   PARAMETERS    OBJECTS
sosreport-template   Description   1 (all set)   1
$ oc process --parameters sosreport-template
NAME                DESCRIPTION                              GENERATOR           VALUE
NODE_NAME           Node Name to collect the sosreport on.
$ oc process sosreport-template -p NODE_NAME=master-0 | oc apply -f -

~~~
