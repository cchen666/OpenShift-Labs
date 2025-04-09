# Metal LB

## Installation

```bash

$ oc new-project metallb-system # Then Install the Metal LB Operator from OperatorHub
```

## Create MetalLB CR

```bash

$ oc apply -f files/metallb-metallb-cr.yaml

$ oc get pods -n metallb-system
NAME                                                  READY   STATUS    RESTARTS   AGE
controller-7b68d765dc-krfqn                           2/2     Running   0          7m56s
frr-k8s-jsr6x                                         6/6     Running   0          7m56s
frr-k8s-lm6fs                                         6/6     Running   0          7m56s
frr-k8s-rnxcw                                         6/6     Running   0          7m56s
frr-k8s-webhook-server-6699cdcd8f-28pjw               1/1     Running   0          7m56s
metallb-operator-controller-manager-54c44df8b-pznhq   1/1     Running   0          30m
metallb-operator-webhook-server-69bbb94fb5-fhqr2      1/1     Running   0          30m
speaker-82swb                                         2/2     Running   0          7m56s
speaker-9768c                                         2/2     Running   0          7m56s
speaker-m97jj                                         2/2     Running   0          7m56s
```

## Test

### Environment: 1 Master + 2 Workers

```bash

$ oc get nodes -o wide
NAME       STATUS   ROLES                         AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                                                KERNEL-VERSION                 CONTAINER-RUNTIME
master-0   Ready    control-plane,master,worker   22h   v1.31.6   172.16.0.101   <none>        Red Hat Enterprise Linux CoreOS 418.94.202503102036-0   5.14.0-427.60.1.el9_4.x86_64   cri-o://1.31.6-2.rhaos4.18.gitda737c9.el9
worker-0   Ready    worker                        48m   v1.31.6   172.16.0.104   <none>        Red Hat Enterprise Linux CoreOS 418.94.202503102036-0   5.14.0-427.60.1.el9_4.x86_64   cri-o://1.31.6-2.rhaos4.18.gitda737c9.el9
worker-1   Ready    worker                        47m   v1.31.6   172.16.0.105   <none>        Red Hat Enterprise Linux CoreOS 418.94.202503102036-0   5.14.0-427.60.1.el9_4.x86_64   cri-o://1.31.6-2.rhaos4.18.gitda737c9.el9

```

### Create Nginx Deployment and Service

```bash

$ oc apply -f files/metallb-deployment-web.yaml

$ oc get all
Warning: apps.openshift.io/v1 DeploymentConfig is deprecated in v4.14+, unavailable in v4.10000+
NAME                       READY   STATUS    RESTARTS   AGE
pod/web-76dbd897d6-x2l6g   1/1     Running   0          7m2s

NAME                    TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)          AGE
service/nginx-service   LoadBalancer   172.30.153.221   172.16.0.120   8080:31903/TCP   7m2s

NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web   1/1     1            1           7m2s

NAME                             DESIRED   CURRENT   READY   AGE
replicaset.apps/web-76dbd897d6   1         1         1       7m2s
replicaset.apps/web-6d5796449f   1         1         1       7h11m

```

* From the KVM Host

```bash

$ ifconfig utun3
utun3: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1500
    inet 10.72.12.237 --> 10.72.12.237 netmask 0xfffffc00

$ w3m http://10.72.36.222:8080 # Pay attention to the port 8080 because the port of service is 8080
Welcome to nginx!

If you see this page, the nginx web server is successfully installed and working. Further configuration is required.

For online documentation and support please refer to nginx.org.
Commercial support is available at nginx.com.

Thank you for using nginx.
```

## TroubleShooting

<https://github.com/metallb/metallb/blob/main/internal/layer2/arp.go>

```bash

$ oc logs controller-b8f4c8565-kzd4l -c controller -n metallb-system

{"caller":"service.go:158","event":"ipAllocated","ip":["172.16.0.120"],"level":"info","msg":"IP address assigned by controller","ts":"2025-04-09T05:47:30Z"}
{"caller":"main.go:127","event":"serviceUpdated","level":"info","msg":"updated service object","ts":"2025-04-09T05:47:30Z"} # svc is created

$ oc describe svc -n test-external-ip # To check which node holds the LB IP, in this case master-0
<Snip>
Events:
  Type    Reason        Age    From                Message
  ----    ------        ----   ----                -------
  Normal  IPAllocated   9m32s  metallb-controller  Assigned IP ["172.16.0.120"]
  Normal  nodeAssigned  8m6s   metallb-speaker     announcing from node "master-0" with protocol "layer2"

$ oc logs speaker-899k9 -c speaker | grep event
{"caller":"announcer.go:126","event":"createARPResponder","interface":"br-ex","level":"info","msg":"created ARP responder for interface","ts":"2025-04-09T05:48:18Z"}
{"caller":"announcer.go:135","event":"createNDPResponder","interface":"br-ex","level":"info","msg":"created NDP responder for interface","ts":"2025-04-09T05:48:18Z"}
{"caller":"announcer.go:126","event":"createARPResponder","interface":"ovn-k8s-mp0","level":"info","msg":"created ARP responder for interface","ts":"2025-04-09T05:48:18Z"}
{"caller":"announcer.go:135","event":"createNDPResponder","interface":"ovn-k8s-mp0","level":"info","msg":"created NDP responder for interface","ts":"2025-04-09T05:48:18Z"} # It creates APR responder on all the interfaces so that it could responde ARP broadcast back to the ARP requester
{"caller":"main.go:420","event":"serviceAnnounced","ips":["172.16.0.120"],"level":"info","msg":"service has IP, announcing","pool":"example","protocol":"layer2","ts":"2025-04-09T05:48:56Z"} # All the NICs will respond ARP for 172.16.0.120

# Delete

{"caller":"service_controller.go:64","controller":"ServiceReconciler","level":"info","start reconcile":"test-external-ip/nginx-service","ts":"2025-04-09T06:02:02Z"}
{"caller":"main.go:464","event":"serviceWithdrawn","ip":["172.16.0.120"],"level":"info","msg":"withdrawing service announcement","reason":"serviceDeleted","ts":"2025-04-09T06:02:02Z"} # announcement is withdrawed if I manually delete the svc

```

```bash

$ sudo iptables -t nat -nL | grep 222 # On the OCP Node
DNAT       tcp  --  0.0.0.0/0            10.72.36.222         tcp dpt:8080 to:172.30.163.110:8080

```
