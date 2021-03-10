# Test on CNI

## Create noop-cni-plugin

### Compile noop-cni-plugin

~~~bash

$ go build Development/cni/noop-cni-plugin
$ cp noop-cni-plugin /opt/multus/bin # /var/lib/cni/bin

~~~

### Create noop-cni-plugin Config

~~~bash
$ cp files/noop-cni.conf /etc/cni/multus/net.d/noop-cni.conf
~~~

## Create Network Attachment Definition

~~~bash
$ oc apply -f files/cni/net-attach-def.yaml
~~~

## Create Pod and Delete Pod

~~~bash
$ oc apply -f files/cni/noop-deployment.yaml
$ oc delete pod --all
~~~

## Check Corresponding Logs

~~~log
$ sudo cat /tmp/cni-noop.log
{"Command":"ADD","Args":{"ContainerID":"e0ae7edec3da4f663d9477ab5ef9fd7aaf8693e54b97d049710fed7eea223c0e","Netns":"/var/run/netns/8275feb9-7a88-4755-8948-35c05f523ffc","IfName":"net1","Args":"IgnoreUnknown=true;K8S_POD_NAMESPACE=test-noop-cni;K8S_POD_NAME=noop-first-bfff7fdcc-n2w6x;K8S_POD_INFRA_CONTAINER_ID=e0ae7edec3da4f663d9477ab5ef9fd7aaf8693e54b97d049710fed7eea223c0e;K8S_POD_UID=b6c0a346-c23d-4915-9670-123b4ba6aaed","Path":"/opt/multus/bin:/var/lib/cni/bin:/usr/libexec/cni","StdinData":"eyJjbmlWZXJzaW9uIjoiMC40LjAiLCJuYW1lIjoibm9vcC1jbmktcGx1Z2luIiwidHlwZSI6Im5vb3AtY25pLXBsdWdpbiJ9"},"NetConf":{"cniVersion":"0.4.0","name":"noop-cni-plugin","type":"noop-cni-plugin","ipam":{},"dns":{}}}
{"Command":"ADD","Args":{"ContainerID":"9b9bd2f584ebee1068d5bb3341c27176c2978bc312e0305e44c5f49d5d6df461","Netns":"/var/run/netns/80095315-6193-4c50-bca6-0494c52437dc","IfName":"net1","Args":"IgnoreUnknown=true;K8S_POD_NAMESPACE=test-noop-cni;K8S_POD_NAME=noop-first-bfff7fdcc-567rz;K8S_POD_INFRA_CONTAINER_ID=9b9bd2f584ebee1068d5bb3341c27176c2978bc312e0305e44c5f49d5d6df461;K8S_POD_UID=d5f2b770-6319-4ceb-9cc3-df37743ec11d","Path":"/opt/multus/bin:/var/lib/cni/bin:/usr/libexec/cni","StdinData":"eyJjbmlWZXJzaW9uIjoiMC40LjAiLCJuYW1lIjoibm9vcC1jbmktcGx1Z2luIiwidHlwZSI6Im5vb3AtY25pLXBsdWdpbiJ9"},"NetConf":{"cniVersion":"0.4.0","name":"noop-cni-plugin","type":"noop-cni-plugin","ipam":{},"dns":{}}}
{"Command":"DEL","Args":{"ContainerID":"e0ae7edec3da4f663d9477ab5ef9fd7aaf8693e54b97d049710fed7eea223c0e","Netns":"/var/run/netns/8275feb9-7a88-4755-8948-35c05f523ffc","IfName":"net1","Args":"IgnoreUnknown=true;K8S_POD_NAMESPACE=test-noop-cni;K8S_POD_NAME=noop-first-bfff7fdcc-n2w6x;K8S_POD_INFRA_CONTAINER_ID=e0ae7edec3da4f663d9477ab5ef9fd7aaf8693e54b97d049710fed7eea223c0e;K8S_POD_UID=b6c0a346-c23d-4915-9670-123b4ba6aaed","Path":"/opt/multus/bin:/var/lib/cni/bin:/usr/libexec/cni","StdinData":"eyJjbmlWZXJzaW9uIjoiMC40LjAiLCJuYW1lIjoibm9vcC1jbmktcGx1Z2luIiwicHJldlJlc3VsdCI6eyJjbmlWZXJzaW9uIjoiMC40LjAiLCJkbnMiOnt9fSwidHlwZSI6Im5vb3AtY25pLXBsdWdpbiJ9"},"NetConf":{"cniVersion":"0.4.0","name":"noop-cni-plugin","type":"noop-cni-plugin","ipam":{},"dns":{}}}
~~~
