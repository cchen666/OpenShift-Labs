# Multus

CNI is the container network interface that provides a pluggable application programming interface to configure network interfaces in Linux containers. Multus CNI is such a plug-in, and is referred to as a meta-plug-in: a CNI plug-in that can run other CNI plug-ins. It works like a wrapper that calls other CNI plug-ins for attaching multiple network interfaces to pods in OpenShift (Kubernetes).

## How Multus is Called by CRI-O

Snip of `/etc/crio/crio.conf.d/00-default` shows CRI-O is looking for CNI configs under `/etc/kubernetes/cni/net.d/`, plugins under `/var/lib/cni/bin` and `/usr/libexec/cni`.

~~~bash
[crio.network]
network_dir = "/etc/kubernetes/cni/net.d/"
plugin_dirs = [
    "/var/lib/cni/bin",
    "/usr/libexec/cni",
]
~~~

## Multus Configuration

~~~bash

$ cat /etc/kubernetes/cni/net.d/00-multus.conf  | jq
{
  "cniVersion": "0.3.1",
  "name": "multus-cni-network",
  "type": "multus",
  "namespaceIsolation": true,
  "globalNamespaces": "default,openshift-multus,openshift-sriov-network-operator",
  "logLevel": "verbose",
  "binDir": "/opt/multus/bin",
  "readinessindicatorfile": "/var/run/multus/cni/net.d/80-openshift-network.conf",
  "kubeconfig": "/etc/kubernetes/cni/net.d/multus.d/multus.kubeconfig",
  "delegates": [ # In case of "delegates", the first delegates network will be used for "Pod IP". Otherwise, "clusterNetwork" will be used for "Pod IP". In this case clusterNetwork is empty.
    {
      "cniVersion": "0.3.1",
      "name": "openshift-sdn",
      "type": "openshift-sdn"
    }
  ]
}

~~~

## Parameters Inside Multus Pod

[Entrypoint Parameters](https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/docs/how-to-use.md, "") shows parameters passed to multus. `--additional-bin-dir` specifies additional CNI binary location.

~~~bash

$ oc rsh multus-46h98
sh-4.4# ps -ef|more
root           1       0  0 Aug19 ?        01:38:13 /bin/bash /entrypoint.sh --multus-conf-file=auto --multus-autoconfig-dir=/host/var/run/multus/cni/net.d --multus-kubeconfig-file-host=/etc/kubernetes/cni
/net.d/multus.d/multus.kubeconfig --readiness-indicator-file=/var/run/multus/cni/net.d/80-openshift-network.conf --cleanup-config-on-exit=true --namespace-isolation=true --multus-log-level=verbose --cni-ve
rsion=0.3.1 --additional-bin-dir=/opt/multus/bin --skip-multus-binary-copy=true - --global-namespaces=default,openshift-multus,openshift-sriov-network-operator

~~~

## Two Methods to Use CNI in net-attach-def

The 'NetworkAttachmentDefinition' is used to setup the network attachment, i.e. secondary interface for the pod, There are two ways to configure the 'NetworkAttachmentDefinition' as following:

* NetworkAttachmentDefinition with json CNI config
* NetworkAttachmentDefinition with CNI config file

### NetworkAttachmentDefinition with json CNI config

Following command creates NetworkAttachmentDefinition. CNI config is in config: field.

~~~bash
# Execute following command at Kubernetes master
cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: macvlan-conf-1
spec:
  config: '{
            "cniVersion": "0.3.0",
            "type": "macvlan",
            "master": "eth1",
            "mode": "bridge",
            "ipam": {
                "type": "host-local",
                "ranges": [
                    [ {
                         "subnet": "10.10.0.0/16",
                         "rangeStart": "10.10.1.20",
                         "rangeEnd": "10.10.3.50",
                         "gateway": "10.10.0.254"
                    } ]
                ]
            }
        }'
EOF
~~~

### NetworkAttachmentDefinition with CNI config file

If NetworkAttachmentDefinition has no spec, multus find a file in defaultConfDir ('/etc/cni/multus/net.d', with same name in the 'name' field of CNI config.

~~~bash
# Execute following command at Kubernetes master
cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: macvlan-conf-2
EOF
# Execute following commands at all Kubernetes nodes (i.e. master and minions)
cat <<EOF > /etc/cni/multus/net.d/macvlan2.conf
{
  "cniVersion": "0.3.0",
  "type": "macvlan",
  "name": "macvlan-conf-2",
  "master": "eth1",
  "mode": "bridge",
  "ipam": {
      "type": "host-local",
      "ranges": [
          [ {
               "subnet": "11.10.0.0/16",
               "rangeStart": "11.10.1.20",
               "rangeEnd": "11.10.3.50"
          } ]
      ]
  }
}
EOF
~~~
