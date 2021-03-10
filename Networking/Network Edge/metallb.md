# Metal LB

## Installation

~~~bash

$ oc new-project metallb-system # Then Install the Metal LB Operator from OperatorHub
~~~

## Create MetalLB CR

~~~bash

$ oc apply -f files/metallb-metallb-cr.yaml

$ oc get all -n metallb-system
NAME                                                       READY   STATUS    RESTARTS   AGE
pod/controller-b8f4c8565-kzd4l                             2/2     Running   0          32m
pod/metallb-operator-controller-manager-8676679d9d-tvvcs   1/1     Running   0          37m
pod/speaker-899k9                                          6/6     Running   0          32m

NAME                                                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)               AGE
service/metallb-controller-monitor-service            ClusterIP   None            <none>        29150/TCP             32m
service/metallb-operator-controller-manager-service   ClusterIP   172.30.246.20   <none>        443/TCP               37m
service/metallb-speaker-monitor-service               ClusterIP   None            <none>        29150/TCP,29151/TCP   32m
service/webhook-service                               ClusterIP   172.30.252.58   <none>        443/TCP               37m

NAME                     DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/speaker   1         1         1       1            1           kubernetes.io/os=linux   32m

NAME                                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/controller                            1/1     1            1           32m
deployment.apps/metallb-operator-controller-manager   1/1     1            1           37m

NAME                                                             DESIRED   CURRENT   READY   AGE
replicaset.apps/controller-b8f4c8565                             1         1         1       32m
replicaset.apps/metallb-operator-controller-manager-8676679d9d   1         1         1       37m
~~~

## Create AddressPools CR

~~~bash

$ oc apply -f files/metallb-addresspools-cr.yaml

~~~

## Test

### Environment: SNO OCP 4.10.30 IP: 10.72.36.88

~~~bash

$ oc get nodes -o wide
NAME                                    STATUS   ROLES           AGE    VERSION           INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                                                        KERNEL-VERSION                 CONTAINER-RUNTIME
dell-per430-35.gsslab.pek2.redhat.com   Ready    master,worker   4d3h   v1.23.5+012e945   10.72.36.88   <none>        Red Hat Enterprise Linux CoreOS 410.84.202208161501-0 (Ootpa)   4.18.0-305.57.1.el8_4.x86_64   cri-o://1.23.3-15.rhaos4.10.git6af791c.el8

~~~

### Create Nginx Deployment and Service

~~~bash

$ oc apply -f files/metallb-deployment-web.yaml
$ oc apply -f files/metallb-svc-web.yaml

$ oc get all
NAME                       READY   STATUS    RESTARTS   AGE
pod/web-6d5796449f-8vskh   1/1     Running   0          7h11m

NAME                    TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)          AGE
service/nginx-service   LoadBalancer   172.30.163.110   10.72.36.222   8080:31903/TCP   7h11m # Pay attention to EXTERNAL-IP = 10.72.36.222 while the addressPools = 10.72.36.222 - 10.72.36.225

NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web   1/1     1            1           7h11m

NAME                             DESIRED   CURRENT   READY   AGE
replicaset.apps/web-6d5796449f   1         1         1       7h11m

~~~

* From a Client

~~~bash

$ ifconfig utun3
utun3: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1500
    inet 10.72.12.237 --> 10.72.12.237 netmask 0xfffffc00

$ w3m http://10.72.36.222:8080 # Pay attention to the port 8080 because the port of service is 8080
Welcome to nginx!

If you see this page, the nginx web server is successfully installed and working. Further configuration is required.

For online documentation and support please refer to nginx.org.
Commercial support is available at nginx.com.

Thank you for using nginx.
~~~

~~~bash

$ oc delete svc nginx-service # Release the IP because the lab could use it

~~~

## TroubleShooting

<https://github.com/metallb/metallb/blob/main/internal/layer2/arp.go>

~~~bash

$ oc logs controller-b8f4c8565-kzd4l -c controller -n metallb-system

{"caller":"level.go:63","event":"ipAllocated","ip":["10.72.36.222"],"level":"info","msg":"IP address assigned by controller","service":"test-external-ip/nginx-service","ts":"2022-09-06T13:00:52.098786622Z"}
{"caller":"level.go:63","event":"serviceUpdated","level":"info","msg":"updated service object","service":"test-external-ip/nginx-service","ts":"2022-09-06T13:00:52.105525249Z"} # svc is created and 10.72.36.222 is allocated
{"caller":"level.go:63","event":"serviceDeleted","level":"info","msg":"service deleted","service":"test-external-ip/nginx-service","ts":"2022-09-06T13:40:09.213370924Z"} # We deleted the svc and the IP is released

$ oc logs speaker-899k9 -c speaker | grep event
{"caller":"level.go:63","event":"createARPResponder","interface":"eno2","level":"info","msg":"created ARP responder for interface","ts":"2022-09-06T12:57:25.427608889Z"}
{"caller":"level.go:63","event":"createARPResponder","interface":"eno3","level":"info","msg":"created ARP responder for interface","ts":"2022-09-06T12:57:25.428799326Z"}
{"caller":"level.go:63","event":"createARPResponder","interface":"eno4","level":"info","msg":"created ARP responder for interface","ts":"2022-09-06T12:57:25.429860382Z"}
{"caller":"level.go:63","event":"createARPResponder","interface":"br-ex","level":"info","msg":"created ARP responder for interface","ts":"2022-09-06T12:57:25.431026362Z"} # It creates APR responder on all the interfaces so that it could responde ARP broadcast back to the ARP requester
{"caller":"level.go:63","level":"info","msg":"node event - forcing sync","node addr":"10.72.36.88","node event":"NodeJoin","node name":"dell-per430-35.gsslab.pek2.redhat.com","ts":"2022-09-06T12:57:25.443214464Z"}
{"caller":"level.go:63","event":"serviceAnnounced","ips":["10.72.36.222"],"level":"info","msg":"service has IP, announcing","pool":"doc-example","protocol":"layer2","service":"test-external-ip/nginx-service","ts":"2022-09-06T13:00:52.106230911Z"} # All the NICs will respond ARP for 10.72.36.222
{"caller":"level.go:63","event":"serviceWithdrawn","ip":null,"level":"info","msg":"withdrawing service announcement","reason":"serviceDeleted","service":"test-external-ip/nginx-service","ts":"2022-09-06T13:40:09.212913624Z"} # svc is deleted and announcement is withdrawed

~~~

~~~bash

$ sudo iptables -t nat -nL | grep 222 # On the OCP Node
DNAT       tcp  --  0.0.0.0/0            10.72.36.222         tcp dpt:8080 to:172.30.163.110:8080

~~~
