# Log Forwarding

## Remote syslog server configuration

~~~bash
# cat /etc/rsyslog.d/from_remote.conf
template(name="DynFile" type="string" string="/var/log/remote/system-%FROMHOST-IP%.log")
ruleset(name="RemoteMachine"){  action(type="omfile" dynaFile="DynFile")  }
module(load="imudp")
input(type="imudp" port="514" ruleset="RemoteMachine")
module(load="imtcp")
input(type="imtcp" port="514" ruleset="RemoteMachine")

# systemctl restart rsyslog
# ss -tunlp | grep 514

udp  UNCONN 0      0                               0.0.0.0:514          0.0.0.0:*                       users:(("rsyslogd",pid=7158,fd=3))
udp  UNCONN 0      0                                  [::]:514             [::]:*                       users:(("rsyslogd",pid=7158,fd=4))
tcp  LISTEN 0      25                              0.0.0.0:514          0.0.0.0:*                       users:(("rsyslogd",pid=7158,fd=5))
tcp  LISTEN 0      25                                 [::]:514             [::]:*                       users:(("rsyslogd",pid=7158,fd=6))
~~~

## Install Cluster Logging operator through operatorhub

~~~ bash
$ oc get csv
NAME                         DISPLAY                     VERSION    REPLACES                            PHASE
<Snip>
cluster-logging.5.1.1-36     Red Hat OpenShift Logging   5.1.1-36   clusterlogging.4.6.0-202106021513   Succeeded
~~~

## Create fluentd DaemonSet

~~~bash

$ cat clusterlogging.yaml
apiVersion: logging.openshift.io/v1
kind: ClusterLogging
metadata:
  annotations:
  name: instance
  namespace: openshift-logging
spec:
  collection:
    logs:
      fluentd: {}
      type: fluentd
  managementState: Managed

$ oc project openshift-logging
$ oc get pods
NAME                                        READY   STATUS    RESTARTS   AGE
cluster-logging-operator-54c6cc7d76-bk8cj   1/1     Running   0          7d3h
fluentd-67zqn                               1/1     Running   0          10m
fluentd-6zvgp                               1/1     Running   0          10m
fluentd-79fw8                               1/1     Running   0          10m
fluentd-bc6tc                               1/1     Running   0          9m55s
fluentd-hdnxr                               1/1     Running   0          10m
fluentd-tgs7c                               1/1     Running   0          10m
~~~

## Create ClusterLogForwarder CR

~~~bash

$ cat logforward.yaml
apiVersion: logging.openshift.io/v1
kind: ClusterLogForwarder
metadata:
  name: instance
  namespace: openshift-logging
spec:
  outputs:
   - name: rsyslog-test
     type: syslog
     syslog:
       facility: local0
       rfc: RFC3164
       payloadKey: message
       severity: informational
     url: 'udp://<remote syslog IP>:514'
  pipelines:
   - name: syslog-test
     inputRefs:
     - infrastructure
     outputRefs:
     - rsyslog-test
     labels:
       syslog: "test"

$ oc apply -f logforward.yaml

~~~

## Confirm on remote syslog server

~~~bash
# ls -l /var/log/remote/
total 8960
-rw------- 1 root root  762509 Sep 23 13:29 system-10.0.147.43.log
-rw------- 1 root root  366019 Sep 23 13:29 system-10.0.155.66.log
-rw------- 1 root root  565752 Sep 23 13:29 system-10.0.164.242.log
-rw------- 1 root root 1272760 Sep 23 13:29 system-10.0.191.144.log
-rw------- 1 root root  255386 Sep 23 13:29 system-10.0.197.49.log
-rw------- 1 root root 3928803 Sep 23 13:29 system-10.0.198.150.log
~~~

## Forward Logs from Specific Project

~~~bash

apiVersion: logging.openshift.io/v1
kind: ClusterLogForwarder
metadata:
  name: instance
  namespace: openshift-logging
spec:
  outputs:
   - name: rsyslog-test
     type: syslog
     syslog:
       facility: local0
       rfc: RFC5424
       severity: informational
     url: 'udp://<IP>:514'
  inputs:
   - name: myapp
     application:
       namespaces:
       - test-ping
  pipelines:
   - name: syslog-test
     inputRefs:
     - myapp
     outputRefs:
     - rsyslog-test

~~~

~~~bash

apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-logging
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-logging
  template:
    metadata:
      labels:
        app: test-logging
      annotations:
    spec:
      containers:
      - name: testlogging
        image: quay.io/ykashtan/ubi8-ip:latest
        command: ["/bin/sh"]
        args: ["-c", "while true;do date; sleep 5;done"]
        securityContext:
          capabilities:
            add: ["NET_RAW", "NET_ADMIN"]

~~~

~~~text

Jan  7 14:44:38 ip-10-0-149-34.us-east-2.compute.internal fluentd {"docker":{"container_id":"c81f347eda1967af4ba37d86a327b0a7d835cf758f0369b667fffd73dfecf2d9"},"kubernetes":{"container_name":"testlogging","namespace_name":"test-ping","pod_name":"test-logging-c46f7c599-nrm7d","container_image":"quay.io/ykashtan/ubi8-ip:latest","container_image_id":"quay.io/ykashtan/ubi8-ip@sha256:c7c0932fcc00a040a5ed538b9a1fc1cdec94f0af5671dd69a9a5e9ec95585e2b","pod_id":"fb518693-6199-48da-a341-84bb66300815","pod_ip":"10.131.1.125","host":"ip-10-0-149-34.us-east-2.compute.internal","labels":{"app":"test-logging","pod-template-hash":"c46f7c599"},"master_url":"https://kubernetes.default.svc","namespace_id":"7a9105c8-e065-46e0-aa24-9930049f2207","namespace_labels":{"kubernetes_io/metadata_name":"test-ping"}},"message":"Fri Jan  7 14:44:36 UTC 2022","level":"unknown","hostname":"ip-10-0-149-34.us-east-2.compute.internal","pipeline_metadata":{"collector":{"ipaddr4":"10.0.149.34","inputname":"fluent-plugin-systemd","name":"fluentd","received_at":"2022-01-07T14:44:37.168013+00:00","version":"1.7.4 1.6.0"}},"@timestamp":"2022-01-07T14:44:36.190651+00:00","viaq_index_name":"app-write","viaq_msg_id":"ODQyYTA1MGQtM2MyMy00MGViLWI3OTktOTJhY2EyOWRjODUy","log_type":"application"}
Jan  7 14:44:43 ip-10-0-149-34.us-east-2.compute.internal fluentd {"docker":{"container_id":"c81f347eda1967af4ba37d86a327b0a7d835cf758f0369b667fffd73dfecf2d9"},"kubernetes":{"container_name":"testlogging","namespace_name":"test-ping","pod_name":"test-logging-c46f7c599-nrm7d","container_image":"quay.io/ykashtan/ubi8-ip:latest","container_image_id":"quay.io/ykashtan/ubi8-ip@sha256:c7c0932fcc00a040a5ed538b9a1fc1cdec94f0af5671dd69a9a5e9ec95585e2b","pod_id":"fb518693-6199-48da-a341-84bb66300815","pod_ip":"10.131.1.125","host":"ip-10-0-149-34.us-east-2.compute.internal","labels":{"app":"test-logging","pod-template-hash":"c46f7c599"},"master_url":"https://kubernetes.default.svc","namespace_id":"7a9105c8-e065-46e0-aa24-9930049f2207","namespace_labels":{"kubernetes_io/metadata_name":"test-ping"}},"message":"Fri Jan  7 14:44:41 UTC 2022","level":"unknown","hostname":"ip-10-0-149-34.us-east-2.compute.internal","pipeline_metadata":{"collector":{"ipaddr4":"10.0.149.34","inputname":"fluent-plugin-systemd","name":"fluentd","received_at":"2022-01-07T14:44:42.168026+00:00","version":"1.7.4 1.6.0"}},"@timestamp":"2022-01-07T14:44:41.193635+00:00","viaq_index_name":"app-write","viaq_msg_id":"YjA5NGU0ZmMtNDEwMi00ZmVhLWI4MzktMzRhMWE0MzM4YjNi","log_type":"application"}
~~~
