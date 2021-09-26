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
