# Troubleshooting

## Information Collection

~~~bash

1) $ for i in $(oc get pods -l component=fluentd | awk '/fluentd/ { print $1 }') ; do oc exec $i -- du -sh /var/lib/fluentd  ; done
2) $ oc exec $es-pod -c elasticsearch  -- es_util --query=_all/_settings?pretty | grep read_only_allow_delete 
3) $ oc get csv -n openshift-logging
4) $ for i in $(oc get pods -l component=elasticsearch --no-headers | grep -i running | awk '{print $1}'); do echo $i; oc exec $i -- df -h;done
5) $ for i in $(oc get pods -l component=fluentd --no-headers | grep -i running | awk '{print $1}'); do echo $i; oc exec $i -- du -sh /var/lib/fluentd/default /var/lib/fluentd/retry_default /var/lib/fluentd;done
6) $ oc exec -c elasticsearch $es_pod -- es_util --query=_cat/nodes?v
7] $ oc exec -c elasticsearch $es_pod -- es_util --query=_cat/health?v
8] $ oc get clusterlogging -oyaml >& clo.text
9) $ oc adm must-gather --image=quay.io/openshift/origin-cluster-logging-operator -- /usr/bin/gather

~~~

## Known Issue

### The elastic-cdm is in Pending and elastic-search-im is in Error state; Fluentd is in Init:CrashLoopBackoff

~~~bash
$ oc get pods -n openshift-logging
NAME                                            READY   STATUS                  RESTARTS   AGE
cluster-logging-operator-6b675d448-vhqkz        1/1     Running                 0          5d10h
curator-1615779000-6q5xr                        0/1     Error                   0          164m
elasticsearch-cdm-6900sppo-1-8689879cd6-x9zgt   0/2     Pending                 0          4d20h
elasticsearch-cdm-6900sppo-2-798b6fbb45-j8k9r   0/2     Pending                 0          4d20h
elasticsearch-cdm-6900sppo-3-7d58df89cb-8dqzz   0/2     Pending                 0          4d20h
elasticsearch-im-app-1615788000-8td8r           0/1     Error                   0          14m
elasticsearch-im-audit-1615788000-w2tch         0/1     Error                   0          14m
elasticsearch-im-infra-1615788000-7bdg4         0/1     Error                   0          14m
fluentd-57m4n                                   0/1     Init:CrashLoopBackOff   1144       4d20h
fluentd-57vrg                                   0/1     Init:0/1                1145       4d20h
fluentd-67ggh                                   0/1     Init:CrashLoopBackOff   1144       4d20h
fluentd-8jjd4                                   0/1     Init:CrashLoopBackOff   1144       4d20h
fluentd-9wlmp                                   0/1     Init:CrashLoopBackOff   1144       4d20h
fluentd-hzsp8                                   0/1     Init:CrashLoopBackOff   1144       4d20h
fluentd-l5mxc                                   0/1     Init:CrashLoopBackOff   1144       4d20h
fluentd-scxsr                                   0/1     Init:CrashLoopBackOff   1144       4d20h
fluentd-x2lv4                                   0/1     Init:0/1                1144       4d20h
kibana-696fb4fb8b-779cd                         2/2     Running                 0          4d20h
~~~

* Since fluentd needs ES to work first, we can focus on ES. The following logs show we don't have enough memory.

~~~bash
$ oc get ev -n openshift-logging
LAST SEEN   TYPE      REASON                 OBJECT                                              MESSAGE
175m        Normal    Scheduled              pod/curator-1615779000-6q5xr                        Successfully assigned openshift-logging/curator-1615779000-6q5xr to ip-10-0-183-117.us-east-2.compute.internal
175m        Normal    AddedInterface         pod/curator-1615779000-6q5xr                        Add eth0 [10.131.3.229/23]
175m        Normal    Pulled                 pod/curator-1615779000-6q5xr                        Container image "registry.redhat.io/openshift4/ose-logging-curator5@sha256:3897eaa7e95d7bd8d34a4ba405ef2f4854884fdb6f05a805b8a99476387ec289" already present on machine
175m        Normal    Created                pod/curator-1615779000-6q5xr                        Created container curator
175m        Normal    Started                pod/curator-1615779000-6q5xr                        Started container curator
175m        Normal    SuccessfulCreate       job/curator-1615779000                              Created pod: curator-1615779000-6q5xr
44m         Warning   BackoffLimitExceeded   job/curator-1615779000                              Job has reached the specified backoff limit
175m        Normal    SuccessfulCreate       cronjob/curator                                     Created job curator-1615779000
44m         Normal    SawCompletedJob        cronjob/curator                                     Saw completed job: curator-1615779000, status: Failed
44m         Normal    SuccessfulDelete       cronjob/curator                                     Deleted job curator-1615692600
6m6s        Warning   FailedScheduling       pod/elasticsearch-cdm-6900sppo-1-8689879cd6-x9zgt   0/9 nodes are available: 9 Insufficient memory.
6m6s        Warning   FailedScheduling       pod/elasticsearch-cdm-6900sppo-2-798b6fbb45-j8k9r   0/9 nodes are available: 9 Insufficient memory.
6m6s        Warning   FailedScheduling       pod/elasticsearch-cdm-6900sppo-3-7d58df89cb-8dqzz   0/9 nodes are available: 9 Insufficient memory.
175m        Normal    Scheduled              pod/elasticsearch-im-app-1615779000-62rsk           Successfully assigned openshift-logging/elasticsearch-im-app-1615779000-62rsk to ip-10-0-142-19.us-east-2.compute.internal
175m        Normal    AddedInterface         pod/elasticsearch-im-app-1615779000-62rsk           Add eth0 [10.130.3.159/23]
175m        Normal    Pulled                 pod/elasticsearch-im-app-1615779000-62rsk           Container image "registry.redhat.io/openshift4/ose-logging-elasticsearch6@sha256:f6e6b28f6c1bc5c35303fbfce0c41daf2671acbe967423276b7fae0eac825202" already present on machine
175m        Normal    Created                pod/elasticsearch-im-app-1615779000-62rsk           Created container indexmanagement
175m        Normal    Started                pod/elasticsearch-im-app-1615779000-62rsk           Started container indexmanagement
175m        Normal    SuccessfulCreate       job/elasticsearch-im-app-1615779000                 Created pod: elasticsearch-im-app-1615779000-62rsk
175m        Warning   BackoffLimitExceeded   job/elasticsearch-im-app-1615779000                 Job has reached the specified backoff limit
160m        Normal    Scheduled              pod/elasticsearch-im-app-1615779900-26m6s           Successfully assigned openshift-logging/elasticsearch-im-app-1615779900-26m6s to ip-10-0-193-254.us-east-2.compute.internal
160m        Normal    AddedInterface         pod/elasticsearch-im-app-1615779900-26m6s           Add eth0 [10.128.4.68/23]
160m        Normal    Pulled                 pod/elasticsearch-im-app-1615779900-26m6s           Container image "registry.redhat.io/openshift4/ose-logging-elasticsearch6@sha256:f6e6b28f6c1bc5c35303fbfce0c41daf2671acbe967423276b7fae0eac825202" already present on machine
160m        Normal    Created                pod/elasticsearch-im-app-1615779900-26m6s           Created container indexmanagement
160m        Normal    Started                pod/elasticsearch-im-app-1615779900-26m6s           Started container indexmanagement
160m        Normal    SuccessfulCreate       job/elasticsearch-im-app-1615779900                 Created pod: elasticsearch-im-app-1615779900-26m6s
160m        Warning   BackoffLimitExceeded   job/elasticsearch-im-app-1615779900                 Job has reached the specified backoff limit
145m        Normal    Scheduled              pod/elasticsearch-im-app-1615780800-vz2q8           Successfully assigned openshift-logging/elasticsearch-im-app-1615780800-vz2q8 to ip-10-0-142-19.us-east-2.compute.internal
145m        Normal    AddedInterface         pod/elasticsearch-im-app-1615780800-vz2q8           Add eth0 [10.130.3.169/23]
145m        Normal    Pulled                 pod/elasticsearch-im-app-1615780800-vz2q8           Container image "registry.redhat.io/openshift4/ose-logging-elasticsearch6@sha256:f6e6b28f6c1bc5c35303fbfce0c41daf2671acbe967423276b7fae0eac825202" already present on machine
145m        Normal    Created                pod/elasticsearch-im-app-1615780800-vz2q8           Created container indexmanagement
145m        Normal    Started                pod/elasticsearch-im-app-1615780800-vz2q8           Started container indexmanagement
145m        Normal    SuccessfulCreate       job/elasticsearch-im-app-1615780800                 Created pod: elasticsearch-im-app-1615780800-vz2q8
145m        Warning   BackoffLimitExceeded   job/elasticsearch-im-app-1615780800                 Job has reached the specified backoff limit
130m        Normal    Scheduled              pod/elasticsearch-im-app-1615781700-dfb9b           Successfully assigned openshift-logging/elasticsearch-im-app-1615781700-dfb9b to ip-10-0-193-254.us-east-2.compute.internal
130m        Normal    AddedInterface         pod/elasticsearch-im-app-1615781700-dfb9b           Add eth0 [10.128.4.70/23]
130m        Normal    Pulled                 pod/elasticsearch-im-app-1615781700-dfb9b           Container image "registry.redhat.io/openshift4/ose-logging-elasticsearch6@sha256:f6e6b28f6c1bc5c35303fbfce0c41daf2671acbe967423276b7fae0eac825202" already present on machine
130m        Normal    Created                pod/elasticsearch-im-app-1615781700-dfb9b           Created container indexmanagement
130m        Normal    Started                pod/elasticsearch-im-app-1615781700-dfb9b           Started container indexmanagement
130m        Normal    SuccessfulCreate       job/elasticsearch-im-app-1615781700                 Created pod: elasticsearch-im-app-1615781700-dfb9b
129m        Warning   BackoffLimitExceeded   job/elasticsearch-im-app-1615781700                 Job has reached the specified backoff limit
115m        Normal    Scheduled              pod/elasticsearch-im-app-1615782600-z6c54           Successfully assigned openshift-logging/elasticsearch-im-app-1615782600-z6c54 to ip-10-0-142-19.us-east-2.compute.internal
115m        Normal    AddedInterface         pod/elasticsearch-im-app-1615782600-z6c54           Add eth0 [10.130.3.179/23]
115m        Normal    Pulled                 pod/elasticsearch-im-app-1615782600-z6c54           Container image "registry.redhat.io/openshift4/ose-logging-elasticsearch6@sha256:f6e6b28f6c1bc5c35303fbfce0c41daf2671acbe967423276b7fae0eac825202" already present on machine
115m        Normal    Created                pod/elasticsearch-im-app-1615782600-z6c54           Created container indexmanagement
115m        Normal    Started                pod/elasticsearch-im-app-1615782600-z6c54           Started container indexmanagement
115m        Normal    SuccessfulCreate       job/elasticsearch-im-app-1615782600                 Created pod: elasticsearch-im-app-1615782600-z6c54
115m        Warning   BackoffLimitExceeded   job/elasticsearch-im-app-1615782600                 Job has reached the specified backoff limit
100m        Normal    Scheduled              pod/elasticsearch-im-app-1615783500-dx5nd           Successfully assigned openshift-logging/elasticsearch-im-app-1615783500-dx5nd to ip-10-0-142-19.us-east-2.compute.internal
100m        Normal    AddedInterface         pod/elasticsearch-im-app-1615783500-dx5nd           Add eth0 [10.130.3.184/23]
100m        Normal    Pulled                 pod/elasticsearch-im-app-1615783500-dx5nd           Container image "registry.redhat.io/openshift4/ose-logging-elasticsearch6@sha256:f6e6b28f6c1bc5c35303fbfce0c41daf2671acbe967423276b7fae0eac825202" already present on machine
100m        Normal    Created                pod/elasticsearch-im-app-1615783500-dx5nd           Created container indexmanagement
100m        Normal    Started                pod/elasticsearch-im-app-1615783500-dx5nd           Started container indexmanagement
100m        Normal    SuccessfulCreate       job/elasticsearch-im-app-1615783500                 Created pod: elasticsearch-im-app-1615783500-dx5nd
100m        Warning   BackoffLimitExceeded   job/elasticsearch-im-app-1615783500                 Job has reached the specified backoff limit
85m         Normal    Scheduled              pod/elasticsearch-im-app-1615784400-vnbfn           Successfully assigned openshift-logging/elasticsearch-im-app-1615784400-vnbfn to ip-10-0-193-254.us-east-2.compute.internal
85m         Normal    AddedInterface         pod/elasticsearch-im-app-1615784400-vnbfn           Add eth0 [10.128.4.74/23]
85m         Normal    Pulled                 pod/elasticsearch-im-app-1615784400-vnbfn           Container image "registry.redhat.io/openshift4/ose-logging-elasticsearch6@sha256:f6e6b28f6c1bc5c35303fbfce0c41daf2671acbe967423276b7fae0eac825202" already present on machine
85m         Normal    Created                pod/elasticsearch-im-app-1615784400-vnbfn           Created container indexmanagement
85m         Normal    Started                pod/elasticsearch-im-app-1615784400-vnbfn           Started container indexmanagement
85m         Normal    SuccessfulCreate       job/elasticsearch-im-app-1615784400                 Created pod: elasticsearch-im-app-1615784400-vnbfn
84m         Warning   BackoffLimitExceeded   job/elasticsearch-im-app-1615784400                 Job has reached the specified backoff limit
70m         Normal    Scheduled              pod/elasticsearch-im-app-1615785300-4vfbd           Successfully assigned openshift-logging/elasticsearch-im-app-1615785300-4vfbd to ip-10-0-193-254.us-east-2.compute.internal
70m         Normal    AddedInterface         pod/elasticsearch-im-app-1615785300-4vfbd           Add eth0 [10.128.4.75/23]
70m         Normal    Pulled                 pod/elasticsearch-im-app-1615785300-4vfbd           Container image "registry.redhat.io/openshift4/ose-logging-elasticsearch6@sha256:f6e6b28f6c1bc5c35303fbfce0c41daf2671acbe967423276b7fae0eac825202" already present on machine
70m         Normal    Created                pod/elasticsearch-im-app-1615785300-4vfbd           Created container indexmanagement
70m         Normal    Started                pod/elasticsearch-im-app-1615785300-4vfbd           Started container indexmanagement
70m         Normal    SuccessfulCreate       job/elasticsearch-im-app-1615785300                 Created pod: elasticsearch-im-app-1615785300-4vfbd
70m         Warning   BackoffLimitExceeded   job/elasticsearch-im-app-1615785300                 Job has reached the specified backoff limit
55m         Normal    Scheduled              pod/elasticsearch-im-app-1615786200-shvtt           Successfully assigned openshift-logging/elasticsearch-im-app-1615786200-shvtt to ip-10-0-193-254.us-east-2.compute.internal
55m         Normal    AddedInterface         pod/elasticsearch-im-app-1615786200-shvtt           Add eth0 [10.128.4.78/23]
55m         Normal    Pulled                 pod/elasticsearch-im-app-1615786200-shvtt           Container image "registry.redhat.io/openshift4/ose-logging-elasticsearch6@sha256:f6e6b28f6c1bc5c35303fbfce0c41daf2671acbe967423276b7fae0eac825202" already present on machine
55m         Normal    Created                pod/elasticsearch-im-app-1615786200-shvtt           Created container indexmanagement
55m         Normal    Started                pod/elasticsearch-im-app-1615786200-shvtt           Started container indexmanagement
55m         Normal    SuccessfulCreate       job/elasticsearch-im-app-1615786200                 Created pod: elasticsearch-im-app-1615786200-shvtt
54m         Warning   BackoffLimitExceeded   job/elasticsearch-im-app-1615786200                 Job has reached the specified backoff limit
40m         Normal    Scheduled              pod/elasticsearch-im-app-1615787100-qt2r2           Successfully assigned openshift-logging/elasticsearch-im-app-1615787100-qt2r2 to ip-10-0-183-117.us-east-2.compute.internal
40m         Normal    AddedInterface         pod/elasticsearch-im-app-1615787100-qt2r2           Add eth0 [10.131.3.239/23]
40m         Normal    Pulled                 pod/elasticsearch-im-app-1615787100-qt2r2           Container image "registry.redhat.io/openshift4/ose-logging-elasticsearch6@sha256:f6e6b28f6c1bc5c35303fbfce0c41daf2671acbe967423276b7fae0eac825202" already present on machine
40m         Normal    Created                pod/elasticsearch-im-app-1615787100-qt2r2           Created container indexmanagement
40m         Normal    Started                pod/elasticsearch-im-app-1615787100-qt2r2           Started container indexmanagement
40m         Normal    SuccessfulCreate       job/elasticsearch-im-app-1615787100                 Created pod: elasticsearch-im-app-1615787100-qt2r2
40m         Warning   BackoffLimitExceeded   job/elasticsearch-im-app-1615787100                 Job has reached the specified backoff limit
25m         Normal    Scheduled              pod/elasticsearch-im-app-1615788000-8td8r           Successfully assigned openshift-logging/elasticsearch-im-app-1615788000-8td8r to ip-10-0-183-117.us-east-2.compute.internal
25m         Normal    AddedInterface         pod/elasticsearch-im-app-1615788000-8td8r           Add eth0 [10.131.3.240/23]
25m         Normal    Pulled                 pod/elasticsearch-im-app-1615788000-8td8r           Container image "registry.redhat.io/openshift4/ose-logging-elasticsearch6@sha256:f6e6b28f6c1bc5c35303fbfce0c41daf2671acbe967423276b7fae0eac825202" already present on machine
25m         Normal    Created                pod/elasticsearch-im-app-1615788000-8td8r           Created container indexmanagement
25m         Normal    Started                pod/elasticsearch-im-app-1615788000-8td8r           Started container indexmanagement
25m         Normal    SuccessfulCreate       job/elasticsearch-im-app-1615788000                 Created pod: elasticsearch-im-app-1615788000-8td8r
25m         Warning   BackoffLimitExceeded   job/elasticsearch-im-app-1615788000                 Job has reached the specified backoff limit
10m         Normal    Scheduled              pod/elasticsearch-im-app-1615788900-mpr6w           Successfully assigned openshift-logging/elasticsearch-im-app-1615788900-mpr6w to ip-10-0-183-117.us-east-2.compute.internal
10m         Normal    AddedInterface         pod/elasticsearch-im-app-1615788900-mpr6w           Add eth0 [10.131.3.241/23]
10m         Normal    Pulled                 pod/elasticsearch-im-app-1615788900-mpr6w           Container image "registry.redhat.io/openshift4/ose-logging-elasticsearch6@sha256:f6e6b28f6c1bc5c35303fbfce0c41daf2671acbe967423276b7fae0eac825202" already present on machine
10m         Normal    Created                pod/elasticsearch-im-app-1615788900-mpr6w           Created container indexmanagement
10m         Normal    Started                pod/elasticsearch-im-app-1615788900-mpr6w           Started container indexmanagement
10m         Normal    SuccessfulCreate       job/elasticsearch-im-app-1615788900                 Created pod: elasticsearch-im-app-1615788900-mpr6w
10m         Warning   BackoffLimitExceeded   job/elasticsearch-im-app-1615788900                 Job has reached the specified backoff limit
175m        Normal    SuccessfulCreate       cronjob/elasticsearch-im-app                        Created job elasticsearch-im-app-1615779000
175m        Normal    SawCompletedJob        cronjob/elasticsearch-im-app                        Saw completed job: elasticsearch-im-app-1615779000, status: Failed
175m        Normal    SuccessfulDelete       cronjob/elasticsearch-im-app                        Deleted job elasticsearch-im-app-1615778100
160m        Normal    SuccessfulCreate       cronjob/elasticsearch-im-app                        Created job elasticsearch-im-app-1615779900
159m        Normal    SawCompletedJob        cronjob/elasticsearch-im-app                        Saw completed job: elasticsearch-im-app-1615779900, status: Failed
159m        Normal    SuccessfulDelete       cronjob/elasticsearch-im-app                        Deleted job elasticsearch-im-app-1615779000
145m        Normal    SuccessfulCreate       cronjob/elasticsearch-im-app                        Created job elasticsearch-im-app-1615780800
144m        Normal    SawCompletedJob        cronjob/elasticsearch-im-app                        Saw completed job: elasticsearch-im-app-1615780800, status: Failed
144m        Normal    SuccessfulDelete       cronjob/elasticsearch-im-app                        Deleted job elasticsearch-im-app-1615779900
130m        Normal    SuccessfulCreate       cronjob/elasticsearch-im-app                        Created job elasticsearch-im-app-1615781700
129m        Normal    SawCompletedJob        cronjob/elasticsearch-im-app                        Saw completed job: elasticsearch-im-app-1615781700, status: Failed
129m        Normal    SuccessfulDelete       cronjob/elasticsearch-im-app                        Deleted job elasticsearch-im-app-1615780800
115m        Normal    SuccessfulCreate       cronjob/elasticsearch-im-app                        Created job elasticsearch-im-app-1615782600
114m        Normal    SawCompletedJob        cronjob/elasticsearch-im-app                        Saw completed job: elasticsearch-im-app-1615782600, status: Failed
114m        Normal    SuccessfulDelete       cronjob/elasticsearch-im-app                        Deleted job elasticsearch-im-app-1615781700
100m        Normal    SuccessfulCreate       cronjob/elasticsearch-im-app                        Created job elasticsearch-im-app-1615783500
100m        Normal    SawCompletedJob        cronjob/elasticsearch-im-app                        Saw completed job: elasticsearch-im-app-1615783500, status: Failed
100m        Normal    SuccessfulDelete       cronjob/elasticsearch-im-app                        Deleted job elasticsearch-im-app-1615782600
85m         Normal    SuccessfulCreate       cronjob/elasticsearch-im-app                        Created job elasticsearch-im-app-1615784400
84m         Normal    SawCompletedJob        cronjob/elasticsearch-im-app                        Saw completed job: elasticsearch-im-app-1615784400, status: Failed
84m         Normal    SuccessfulDelete       cronjob/elasticsearch-im-app                        Deleted job elasticsearch-im-app-1615783500
~~~

~~~yaml
apiVersion: "logging.openshift.io/v1"
kind: "ClusterLogging"
metadata:
  name: "instance"
  namespace: "openshift-logging"
spec:
  managementState: "Managed"  
  logStore:
    type: "elasticsearch"  
    retentionPolicy:
      application:
        maxAge: 1d
      infra:
        maxAge: 7d
      audit:
        maxAge: 7d
    elasticsearch:
      nodeCount: 3
      storage:
        storageClassName: "<storage-class-name>"
        size: 200G
      resources:
        requests:
          memory: "8Gi"    <==================
      proxy:
        resources:
          limits:
            memory: 256Mi
          requests:
             memory: 256Mi
      redundancyPolicy: "SingleRedundancy"
  visualization:
    type: "kibana"  
    kibana:
      replicas: 1
  curation:
    type: "curator"
    curator:
      schedule: "30 3 * * *"
  collection:
    logs:
      type: "fluentd"  
      fluentd: {}
~~~

* Increase the node's memory solves the issue

~~~bash
$ oc get pods -n openshift-logging
NAME                                            READY   STATUS    RESTARTS   AGE
cluster-logging-operator-6b675d448-v2wgp        1/1     Running   0          10m
elasticsearch-cdm-6900sppo-1-7cf64d6d66-jrgc5   2/2     Running   0          52s
elasticsearch-cdm-6900sppo-2-56959d55bf-jzbwx   2/2     Running   0          51s
elasticsearch-cdm-6900sppo-3-6df464b668-z5wsx   2/2     Running   0          50s
fluentd-5mrwf                                   1/1     Running   0          51s
fluentd-6w56x                                   1/1     Running   0          51s
fluentd-8lzrm                                   1/1     Running   0          51s
fluentd-cbcls                                   1/1     Running   0          51s
fluentd-hp5jt                                   1/1     Running   0          51s
fluentd-kwjl9                                   1/1     Running   0          51s
fluentd-lnvxq                                   1/1     Running   0          51s
fluentd-qk9kc                                   1/1     Running   0          51s
fluentd-zfszl                                   1/1     Running   0          51s
kibana-696fb4fb8b-gfqtj                         2/2     Running   0          21s
~~~
