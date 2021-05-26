#### pods
~~~
$ oc get pods -o wide -n openshift-dns
$ oc rsh dns-default-6bsrz
Defaulting container name to dns.
Use 'oc describe pod/dns-default-6bsrz -n openshift-dns' to see all of the containers in this pod.
sh-4.4# cat /etc/coredns/Corefile
.:5353 {
    errors
    health {
        lameduck 20s
    }
    ready
    kubernetes cluster.local in-addr.arpa ip6.arpa {
        pods insecure
        upstream
        fallthrough in-addr.arpa ip6.arpa
    }
    prometheus 127.0.0.1:9153
    forward . /etc/resolv.conf {
        policy sequential
    }
    cache 900 {
        denial 9984 30
    }
    reload

# cat /etc/resolv.conf
search us-east-2.compute.internal
nameserver 10.0.0.2
~~~
#### How the flow works
~~~
$ oc get svc
NAME          TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)                  AGE
dns-default   ClusterIP   172.30.0.10   <none>        53/UDP,53/TCP,9154/TCP   20d

cchens-MacBook-Pro-2:~ cchen$ oc project myproject
Now using project "myproject" on server "https://api.mycluster.nancyge.com:6443".
cchens-MacBook-Pro-2:~ cchen$ oc get pods
NAME                                               READY   STATUS    RESTARTS   AGE
deploy-python-openshift-tutorial-fc74868f5-s9gfk   1/1     Running   0          5d5h
cchens-MacBook-Pro-2:~ cchen$ oc rsh deploy-python-openshift-tutorial-fc74868f5-s9gfk
/app $ cat /etc/resolv.conf
search myproject.svc.cluster.local svc.cluster.local cluster.local us-east-2.compute.internal
nameserver 172.30.0.10

~~~
#### Static entries for image-registry when launching coreDNS
~~~
# cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
172.30.146.132 image-registry.openshift-image-registry.svc image-registry.openshift-image-registry.svc.cluster.local # openshift-generated-node-resolver
~~~
#### CoreDNS k8s plugin
https://coredns.io/plugins/kubernetes/
#### Configure the forward zone
https://docs.openshift.com/container-platform/4.7/networking/dns-operator.html
#### Troubleshooting
https://access.redhat.com/solutions/3804501
#### Collect tcpdump
https://access.redhat.com/solutions/4537671
#### Test the query
~~~
* Internal query

$ for dnspod in `oc get pods -n openshift-dns -o name --no-headers`; do echo "Testing $dnspod"; for dnsip in `oc get pods -n openshift-dns -o go-template='{{ range .items }} {{index .status.podIP }} {{end}}'`; do echo -e "\t Making query to $dnsip"; oc exec -n openshift-dns $dnspod -- dig @$dnsip kubernetes.default.svc.cluster.local -p 5353 +short 2>/dev/null; done; done

* External query

$ for dnspod in `oc get pods -n openshift-dns -o name --no-headers`; do echo "Testing $dnspod"; for dnsip in `oc get pods -n openshift-dns -o go-template='{{ range .items }} {{index .status.podIP }} {{end}}'`; do echo -e "\t Making query to $dnsip"; oc exec -n openshift-dns $dnspod -- dig @$dnsip www.baidu.com -p 5353 +short 2>/dev/null; done; done
~~~
