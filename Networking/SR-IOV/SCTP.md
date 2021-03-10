# SCTP

## Load SCTP Module

~~~bash

$ oc apply -f files/mc-load-sctp.yaml

~~~

## Create Test Pod

~~~bash

$ oc new-project test-sctp
$ oc apply -f files/sctp-client.yaml
$ oc apply -f files/sctp-server.yaml

~~~

## Test SCTP Link

~~~bash
$ oc get pods -o wide
NAME         READY   STATUS    RESTARTS   AGE   IP            NODE                                    NOMINATED NODE   READINESS GATES
sctpclient   1/1     Running   0          31h   10.128.0.81   dell-per430-35.gsslab.pek2.redhat.com   <none>           <none>
sctpserver   1/1     Running   0          31h   10.128.0.79   dell-per430-35.gsslab.pek2.redhat.com   <none>           <none>

$ oc rsh sctpserver
sh-4.4# nc -l 30102 --sctp

# Open Another Terminal to start tcpdump

$ NAME=sctpclient
$ NAMESPACE=test-sctp
$ pod_id=$(chroot /host crictl pods --namespace ${NAMESPACE} --name ${NAME} -q)
$  ns_path="/host/$(chroot /host bash -c "crictl inspectp $pod_id | jq '.info.runtimeSpec.linux.namespaces[]|select(.type==\"network\").path' -r")"
$ nsenter --net=${ns_path} -- tcpdump -nn -i eth0

# Open a 3rd Terminal
$ oc rsh sctpclient
sh-4.4# nc 10.128.0.79 30102 --sctp
Send message
<Ctrl + C>

# Check the Tcpdump Result; INIT packets for 4 handshakes, Data and SACK is because we send "Send message" through SCTP link. SCTP has its own Heartbeat mech with HB REQ and HB ACK pair. Finally after we hit Ctrl + C, the SCTP link is finished with SHUTDOWN (3 handshakes).

14:50:55.792111 IP 10.128.0.81.60002 > 10.128.0.79.30102: sctp (1) [INIT] [init tag: 1008070933] [rwnd: 106496] [OS: 10] [MIS: 65535] [init TSN: 2431437204]
14:50:55.792577 IP 10.128.0.79.30102 > 10.128.0.81.60002: sctp (1) [INIT ACK] [init tag: 1296372942] [rwnd: 106496] [OS: 10] [MIS: 10] [init TSN: 2317599708]
14:50:55.792594 IP 10.128.0.81.60002 > 10.128.0.79.30102: sctp (1) [COOKIE ECHO]
14:50:55.792641 IP 10.128.0.79.30102 > 10.128.0.81.60002: sctp (1) [COOKIE ACK]
14:51:01.976771 IP 10.128.0.81.60002 > 10.128.0.79.30102: sctp (1) [DATA] (B)(E) [TSN: 2431437204] [SID: 0] [SSEQ 0] [PPID 0x0]
14:51:01.976838 IP 10.128.0.79.30102 > 10.128.0.81.60002: sctp (1) [SACK] [cum ack 2431437204] [a_rwnd 106491] [#gap acks 0] [#dup tsns 0]
14:51:31.357135 IP 10.128.0.79.30102 > 10.128.0.81.60002: sctp (1) [HB REQ]
14:51:31.357154 IP 10.128.0.81.60002 > 10.128.0.79.30102: sctp (1) [HB ACK]
14:51:32.508429 IP 10.128.0.81.60002 > 10.128.0.79.30102: sctp (1) [HB REQ]
14:51:32.508472 IP 10.128.0.79.30102 > 10.128.0.81.60002: sctp (1) [HB ACK]
14:52:09.404148 IP 10.128.0.81.60002 > 10.128.0.79.30102: sctp (1) [SHUTDOWN]
14:52:09.404207 IP 10.128.0.79.30102 > 10.128.0.81.60002: sctp (1) [SHUTDOWN ACK]
14:52:09.404219 IP 10.128.0.81.60002 > 10.128.0.79.30102: sctp (1) [SHUTDOWN COMPLETE]
~~~
