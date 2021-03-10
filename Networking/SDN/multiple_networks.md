# SDN

## Edit network operator

~~~bash
$ oc edit networks.operator.openshift.io cluster

spec:
  additionalNetworks:
  - name: test-network-1
    namespace: test-1
    rawCNIConfig: '{ "cniVersion": "0.3.1", "name": "test-network-1", "type": "ipvlan","master": "ens5", "mode": "l2", "ipam": { "type": "static", "addresses": [ { "address": "192.168.1.122/24" } ] } }'
    type: Raw
  - name: test-network-2
    namespace: test-1
    rawCNIConfig: '{ "cniVersion": "0.3.1", "name": "test-network-1", "type": "ipvlan","master": "ens5", "mode": "l2", "ipam": { "type": "static", "addresses": [ { "address": "192.168.1.23/24" } ] } }'
    type: Raw
~~~

## Create pod yaml

~~~bash
---
kind: Pod
apiVersion: v1
metadata:
  name: hello-openshift-1
  creationTimestamp:
  labels:
    name: hello-openshift-1
  annotations:
    k8s.v1.cni.cncf.io/networks: test-network-1
spec:
  containers:
  - name: hello-openshift-1
    image: ubuntu:latest
    command: [ "/bin/bash", "-c", "--" ]
    args: [ "while true; do sleep 30; done;" ]
    ports:
    - containerPort: 8080
      protocol: TCP
    resources: {}
    volumeMounts:
    - name: tmp
      mountPath: "/tmp"
    terminationMessagePath: "/dev/termination-log"
    imagePullPolicy: IfNotPresent
    securityContext:
      capabilities: {}
      privileged: false
      volumes:
      - name: tmp
        emptyDir: {}
      restartPolicy: Always
      dnsPolicy: ClusterFirst
      serviceAccount: ''
    status: {}
~~~

## Check the result

~~~bash
$ oc create -f hello-openshift-1.yaml
$ oc describe pod hello-openshift-1

<Snip>

k8s.v1.cni.cncf.io/networks: test-network-1
k8s.v1.cni.cncf.io/networks-status:
  [{
      "name": "",
      "interface": "eth0",
      "ips": [
          "10.128.3.50"
      ],
      "default": true,
      "dns": {}
  },{
      "name": "test-1/test-network-1",
      "interface": "net1",
      "ips": [
          "192.168.1.122"
      ],
      "mac": "0a:e4:69:77:90:c2",
      "dns": {}
  }]
~~~
