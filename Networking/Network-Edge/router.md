# Router

## Haproxy will regenerate entries when pods get deleted

* Check current endpoints

~~~bash
$ oc get ep
NAME                                   ENDPOINTS                            AGE
deploy-python-openshift-s2i-tutorial   10.128.2.122:8080,10.131.0.11:8080   73d
~~~

* Login to the router pod and backup the `haproxy.config` file.

~~~bash
$ oc get pod  -n openshift-ingress -o wide
NAME                              READY   STATUS    RESTARTS   AGE   IP           NODE                                         NOMINATED NODE   READINESS GATES
router-default-8549f7c945-6tq7c   1/1     Running   0          39d   10.128.4.8   ip-10-0-193-254.us-east-2.compute.internal   <none>           <none>
router-default-8549f7c945-jctbv   1/1     Running   0          39d   10.131.0.3   ip-10-0-220-0.us-east-2.compute.internal     <none>           <none>

$ oc exec -it router-default-8549f7c945-6tq7c -n openshift-ingress  /bin/bash
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.

$ ps -ef
UID          PID    PPID  C STIME TTY          TIME CMD
1000530+       1       0  0 Mar15 ?        01:01:48 /usr/bin/openshift-router --v=2
1000530+    5743       0  0 Mar31 pts/0    00:00:00 /bin/sh
1000530+   10405       1  0 06:48 ?        00:00:00 /usr/sbin/haproxy -f /var/lib/haproxy/conf/haproxy.config -p /var/lib/haproxy/run/haproxy.pid -x /var/lib/hapr
1000530+   10414       0  0 06:50 pts/1    00:00:00 /bin/bash
1000530+   10420   10414  0 06:50 pts/1    00:00:00 ps -ef

$ cp /var/lib/haproxy/conf/haproxy.config /tmp/
~~~

* Delete one of the pods

~~~bash
$ oc delete pod deploy-python-openshift-s2i-tutorial-55655bcf77-5hrzc
pod "deploy-python-openshift-s2i-tutorial-55655bcf77-5hrzc" deleted
~~~

* Compare the haproxy.config

~~~bash
$ diff /tmp/haproxy.config /var/lib/haproxy/conf/haproxy.config
204c204
<   server pod:deploy-python-openshift-s2i-tutorial-55655bcf77-5hrzc:deploy-python-openshift-s2i-tutorial:8080-tcp:10.131.0.11:8080 10.131.0.11:8080 cookie cde73a2d20af88d0f675474338b97374 weight 256 check inter 5000ms
---
>   server pod:deploy-python-openshift-s2i-tutorial-55655bcf77-jxhwk:deploy-python-openshift-s2i-tutorial:8080-tcp:10.128.5.241:8080 10.128.5.241:8080 cookie 002de886c11d29e9e24951e2af267157 weight 256 check inter 5000ms
~~~

* The endpoints also get refreshed

~~~bash
$ oc get ep
NAME                                   ENDPOINTS                             AGE
deploy-python-openshift-s2i-tutorial   10.128.2.122:8080,10.128.5.241:8080   73d
~~~

## Create TLS termination route

<https://docs.openshift.com/container-platform/3.10/architecture/networking/routes.html>

## Use nodeselector to bind the router pods to worker nodes

### openshift-ingress operator configuration - Edit or add IngressController

<https://docs.openshift.com/container-platform/4.6/networking/configuring_ingress_cluster_traffic/configuring-ingress-cluster-traffic-ingress-controller.html>

Multiple IngressController create multiple routers. By matching the label, the route will always bind to the routers that are created by the unique IngressController.

~~~bash
$ oc project openshift-ingress-operator
$ oc edit ingresscontroller default # For example, change replica from 2 to 3 and you'll find 3 router-default pods Running
$ oc get pods -n openshift-ingress

NAME                              READY   STATUS    RESTARTS   AGE
router-default-8549f7c945-6tq7c   1/1     Running   0          39d
router-default-8549f7c945-jctbv   1/1     Running   0          39d
router-default-8549f7c945-mkhgb   1/1     Running   0          5m36s
~~~

## Configure Internal/External Ingress Controller sharding on an existing OpenShift 4.x cluster

<https://access.redhat.com/solutions/4981211>

## How to avoid that the default ingresscontroller serves routes of all projects when using router sharding in OpenShift 4.x

<https://access.redhat.com/solutions/5097511>

~~~bash

$ oc apply -f files/router-sharded.yaml

$ oc new-project test-sharded

$ oc edit namespace test-sharded

  labels:
    kubernetes.io/metadata.name: test-sharded
    type: sharded  <-------

$ oc new-app openshift/hello-openshift

$ oc expose service/hello-openshift --hostname hello.apps-sharded.mycluster.nancyge.com

$ oc describe route hello-openshift
Name:  hello-openshift
Namespace: test-sharded
Created: 3 minutes ago
Labels:   app=hello-openshift
   app.kubernetes.io/component=hello-openshift
   app.kubernetes.io/instance=hello-openshift
Annotations:  <none>
Requested Host:  hello.apps-sharded.mycluster.nancyge.com
      exposed on router default (host router-default.apps.mycluster.nancyge.com) 3 minutes ago
      exposed on router sharded (host router-sharded.apps-sharded.mycluster.nancyge.com) 3 minutes ago

$ curl hello.apps-sharded.mycluster.nancyge.com
Hello OpenShift!

$ oc get pods -n openshift-ingress
NAME                              READY   STATUS    RESTARTS   AGE
router-default-6dc65bb84c-8j99h   1/1     Running   0          12d
router-default-6dc65bb84c-ppmj7   1/1     Running   0          12d
router-sharded-67d84c9489-4rgxl   1/1     Running   0          13m
router-sharded-67d84c9489-92pjd   1/1     Running   0          13m
~~~

### Known Issue

* We can see the default ingresscontroller still has hello-openshift entries by running `oc describe route hello-openshift`. We see two entries in Request Host.

~~~bash

$ oc rsh router-default-6dc65bb84c-ppmj7

$ grep hello-openshift /var/lib/haproxy/conf/haproxy.config
backend be_http:test-sharded:hello-openshift
  server pod:hello-openshift-7b8c68587c-zrlz9:hello-openshift:8080-tcp:10.131.1.208:8080 10.131.1.208:8080 cookie 999e7f67aedb20d52c82d23f151bb779 weight 256 check inter 5000ms

$ grep hello-openshift /var/lib/haproxy/conf/os_http_be.map
^hello\.apps-sharded\.mycluster\.nancyge\.com\.?(:[0-9]+)?(/.*)?$ be_http:test-sharded:hello-openshift

~~~

* In order to remove the entries from router-default POD, we need to update default ingresscontroller with proper Selector as well.

~~~bash

$ oc edit ingresscontroller default -n openshift-ingress-operator

  namespaceSelector:
    matchExpressions:
    - key: type
      operator: NotIn
      values:
      - sharded

~~~
