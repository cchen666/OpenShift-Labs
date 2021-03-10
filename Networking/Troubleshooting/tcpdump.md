# TCPDUMP

## 4.8 and Before

~~~bash

$ oc debug node/<>

NAME=<pod-name>
NAMESPACE=<pod-namespace>
pod_id=$(chroot /host crictl pods --namespace ${NAMESPACE} --name ${NAME} -q)
pid=$(chroot /host bash -c "runc state $pod_id | jq .pid")
nsenter_parameters="-n -t $pid"

~~~

## 4.9 and Later

~~~bash

NAME=<pod-name>
NAMESPACE=<pod-namespace>
pod_id=$(chroot /host crictl pods --namespace ${NAMESPACE} --name ${NAME} -q)
ns_path="/host/$(chroot /host bash -c "crictl inspectp $pod_id | jq '.info.runtimeSpec.linux.namespaces[]|select(.type==\"network\").path' -r")"
nsenter_parameters="--net=${ns_path}"

~~~

## Only Capture SYN or ACK

~~~bash

$ tcpdump -i <interface> "tcp[tcpflags] & (tcp-syn) != 0"
$ tcpdump -i <interface> "tcp[tcpflags] & (tcp-ack) != 0"
$ tcpdump -i <interface> "tcp[tcpflags] & (tcp-fin) != 0"
$ tcpdump -r <interface> "tcp[tcpflags] & (tcp-syn|tcp-ack) != 0"

~~~
