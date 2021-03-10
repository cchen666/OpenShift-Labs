# Assisted Installer on KVM Host

## Create Libvirt Network on Host

~~~bash
$ cat << EOF > net.xml
<network xmlns:dnsmasq='http://libvirt.org/schemas/network/dnsmasq/1.0'>
  <name>ocp-dev</name>
  <uuid>5e5f3fca-1bb0-4fb7-a875-1fd34a83713c</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr1' stp='on' delay='0'/>
  <mac address='52:54:00:f0:79:30'/>
  <dns>
    <host ip='192.168.123.2'>
      <hostname>api.mycluster.ocp.com</hostname>
    </host>
  </dns>
  <ip address='192.168.123.1' netmask='255.255.255.0'>
      <dhcp>
      <range start='192.168.123.2' end='192.168.123.254'/>
      <host mac='02:01:00:00:00:50' name='lb.mycluster.ocp.com' ip='192.168.123.2'/>
      <host mac='02:01:00:00:00:60' name='master-0.mycluster.ocp.com' ip='192.168.123.6'/>
      <host mac='02:01:00:00:00:61' name='master-1.mycluster.ocp.com' ip='192.168.123.7'/>
      <host mac='02:01:00:00:00:62' name='master-2.mycluster.ocp.com' ip='192.168.123.8'/>
      <host mac='02:01:00:00:00:70' name='worker-0.mycluster.ocp.com' ip='192.168.123.9'/>
      <host mac='02:01:00:00:00:71' name='worker-1.mycluster.ocp.com' ip='192.168.123.10'/>
    </dhcp>
  </ip>
  <dnsmasq:options>
    <dnsmasq:option value='auth-server=mycluster.ocp.com,'/>
    <dnsmasq:option value='auth-zone=mycluster.ocp.com'/>
    <dnsmasq:option value='host-record=lb.mycluster.ocp.com,192.168.123.2'/>
    <dnsmasq:option value='cname=*.apps.mycluster.ocp.com,lb.mycluster.ocp.com'/>
  </dnsmasq:options>
</network>

EOF

$ virsh net-create net.xml
$ virsh net-autostart ocp-dev
~~~

## Navigate to assited installer console

~~~bash
https://console.redhat.com/openshift/assisted-installer/clusters/~new
Cluster Name: mycluster
Base Domain: ocp.com
Next
Generate Discovery ISO -> Copy your hosts ssh public key -> Generate Discovery ISO -> Download the ISO and save it
~~~

## Optional: Install Haproxy LoadBalancer VM

~~~bash

$ virt-install -n ocp-haproxy \
--memory 1024 \
--os-variant=fedora-coreos-stable \
--vcpus=1  \
--accelerate  \
--cpu host-passthrough,cache.mode=passthrough  \
--disk path=/home/sno/images/ocp-haproxy.qcow2,size=120  \
--network network=ocp-dev,mac=02:01:00:00:00:50  \
--cdrom rhel8u4.iso

$ yum install haproxy

$ cat << EOF > /etc/haproxy/haproxy.cfg
# Global settings
#---------------------------------------------------------------------
global
    maxconn     20000
    log         /dev/log local0 info
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
#    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          300s
    timeout server          300s
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 20000
listen stats
    bind :9000
    mode http
    stats enable
    stats uri /

# all frontend
frontend  router-http-traffic
    bind *:80
    default_backend router-http-traffic
    mode tcp
    option tcplog

frontend  router-https-traffic
    bind *:443
    default_backend router-https-traffic
    mode tcp
    option tcplog

frontend  k8s-api-server
    bind *:6443
    default_backend k8s-api-server
    mode tcp
    option tcplog

frontend  machine-config-server
    bind *:22623
    default_backend machine-config-server
    mode tcp
    option tcplog

# all backend
backend router-http-traffic
 balance source
 mode tcp
 server   worker-0.mycluster.ocp.com 192.168.123.9:80 check

backend router-https-traffic
 balance source
 mode tcp
 server   worker-0.mycluster.ocp.com 192.168.123.9:80 check

backend k8s-api-server
 balance source
 mode tcp
 server   master-0.mycluster.ocp.com 192.168.123.6:6443 check
 server   master-1.mycluster.ocp.com 192.168.123.7:6443 check
 server   master-2.mycluster.ocp.com 192.168.123.8:6443 check

backend machine-config-server
 balance source
 mode tcp
 server   master-0.mycluster.ocp.com 192.168.123.6:22623 check
 server   master-1.mycluster.ocp.com 192.168.123.7:22623 check
 server   master-2.mycluster.ocp.com 192.168.123.8:22623 check

EOF

$ setenforce 0
$ systemctl stop firewalld
$ systemctl restart haproxy
~~~

## Install master and worker VMs

~~~bash
$ IMAGE=/home/sno/images/discovery_image_mycluster.iso
$ for i in 0 1 2; do
virt-install -n ocp-master-$i \
--memory 16384 \
--os-variant=fedora-coreos-stable \
--vcpus=4  \
--accelerate  \
--cpu host-passthrough,cache.mode=passthrough  \
--disk path=/home/sno/images/ocp-master-$i.qcow2,size=120  \
--network network=ocp-dev,mac=02:01:00:00:00:6$i  \
--cdrom $IMAGE &
done

$ for i in 0 1; do
virt-install -n ocp-worker-$i \
--memory 8192 \
--os-variant=fedora-coreos-stable \
--vcpus=2  \
--accelerate  \
--cpu host-passthrough,cache.mode=passthrough  \
--disk path=/home/sno/images/ocp-worker-$i.qcow2,size=120  \
--network network=ocp-dev,mac=02:01:00:00:00:7$i  \
--cdrom $IMAGE &
done

$ for i in 0; do
virt-install -n ocp-infra-$i \
--memory 8192 \
--os-variant=fedora-coreos-stable \
--vcpus=2  \
--accelerate  \
--cpu host-passthrough,cache.mode=passthrough  \
--disk path=/home/sno/images/ocp-infra-$i.qcow2,size=120  \
--network network=ocp-dev,mac=02:01:00:00:00:8$i  \
--cdrom $IMAGE &
done

~~~

## Kick off the Installation in Assited Installer Console

~~~text
The 5 hosts should be discovered and assign 3 masters + 2 workers and then press Install
Important: Keep note of API VIP Address and Ingress VIP Address
~~~

## Post Install

### Update API VIP Address and Ingress VIP Address

* Note: If you already built a Haproxy LB VM, you don't need to do this step.
* Update the ocp-dev to reflect API and Ingress VIP. You get these addresses in Assisted Installer Console

~~~bash
$ virsh net-edit ocp-dev
<Snip>

  <dns>
    <host ip='192.168.123.251'>    <--------- API VIP
      <hostname>api.mycluster.ocp.com</hostname>
    </host>
  </dns>

<Snip>

    <dnsmasq:options>
    <dnsmasq:option value='auth-server=mycluster.ocp.com,'/>
    <dnsmasq:option value='auth-zone=mycluster.ocp.com'/>
    <dnsmasq:option value='host-record=lb.mycluster.ocp.com,192.168.123.11'/>  <--------- Ingress VIP
    <dnsmasq:option value='cname=*.apps.mycluster.ocp.com,lb.mycluster.ocp.com'/>
  </dnsmasq:options>

<Snip>

$ virsh net-destroy ocp-dev
$ virsh net-start ocp-dev
$ systemctl restart libvirtd
~~~

### Configure Integrated Image Registry by Using Host NFS

~~~bash
$ yum install nfs-utils -y

$ mkdir /home/imagepv
$ chown nobody:nobody /home/imagepv
$ chmod 777 /home
$ chmod 777 /home/imagepv

$ cat /etc/exports
/home/imagepv    *(rw,sync,no_wdelay,no_root_squash,insecure,fsid=0)

$ cat << EOF > pv.yaml

apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv
spec:
  capacity:
    storage: 500Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  nfs:
    path: /home/imagepv
    server: 192.168.123.1

EOF

$ oc apply -f pv.yaml

$ oc edit configs.imageregistry.operator.openshift.io

  managementState: Managed   <--------
  observedConfig: null
  operatorLogLevel: Normal
  proxy: {}


  storage:
    managementState: Managed <--------
    pvc:                     <--------
      claim:                 <--------

$ oc new-app https://github.com/cchen666/openshift-flask
$ oc expose svc/openshift-flask
$ curl openshift-flask-test-1.apps.mycluster.ocp.com
<!DOCTYPE html>
<html lang="en" dir="ltr">
  <head>
    <meta charset="utf-8">
    <title>Flask教学</title>
  </head>
  <body>
    <h1>我的第一个Flask网站</h1>
    <p> Flask是一个使用Python编写的轻量级Web应用框架。</p>
  </body>
~~~

### Dig More

* The Assited Installer provides Keepalived (VIP) and Haproxy in openshift-kni-infra project and that's why we don't need to manually install an Haproxy LB VM.

~~~bash

$ oc get pods -n openshift-kni-infra
NAME                  READY   STATUS    RESTARTS   AGE
coredns-master-0      2/2     Running   2          18h
coredns-master-1      2/2     Running   2          18h
coredns-master-2      2/2     Running   2          18h
coredns-worker-0      2/2     Running   2          18h
coredns-worker-1      2/2     Running   2          18h
haproxy-master-0      2/2     Running   2          18h
haproxy-master-1      2/2     Running   6          18h
haproxy-master-2      2/2     Running   2          18h
keepalived-master-0   2/2     Running   2          18h
keepalived-master-1   2/2     Running   2          18h
keepalived-master-2   2/2     Running   2          18h
keepalived-worker-0   2/2     Running   2          18h
keepalived-worker-1   2/2     Running   2          18h

$ oc project openshift-kni-infra
$ oc rsh keepalived-master-0
$ grep virtual_ipaddress /etc/keepalived/keepalived.conf -A2
    virtual_ipaddress {
        192.168.123.251/32
    }
--
    virtual_ipaddress {
        192.168.123.11/32
    }
$ exit

# API:

$ oc rsh haproxy-master-0
$ cat /etc/haproxy/haproxy.cfg

backend masters
   option  httpchk GET /readyz HTTP/1.0
   option  log-health-checks
   balance roundrobin
   server master-0 192.168.123.6:6443 weight 1 verify none check check-ssl inter 1s fall 2 rise 3
   server master-1 192.168.123.7:6443 weight 1 verify none check check-ssl inter 1s fall 2 rise 3
   server master-2 192.168.123.8:6443 weight 1 verify none check check-ssl inter 1s fall 2 rise 3

# Ingress:

$ ssh core@192.168.123.9
[root@worker-0 ~]# ip a | grep 192
    inet 192.168.123.9/24 brd 192.168.123.255 scope global dynamic noprefixroute enp1s0
    inet 192.168.123.11/32 scope global enp1s0

$ oc get pods -o wide -n openshift-ingress
NAME                              READY   STATUS    RESTARTS   AGE   IP               NODE       NOMINATED NODE   READINESS GATES
router-default-6fbdd9cfcf-x8ccv   1/1     Running   3          19h   192.168.123.10   worker-1   <none>           <none>
router-default-6fbdd9cfcf-zj58k   1/1     Running   2          19h   192.168.123.9    worker-0   <none>           <none>
~~~

## Clean Up

~~~bash

for i in 0 1 2; do
virsh destroy ocp-master-$i
virsh undefine ocp-master-$i
rm -rf /home/sno/images/ocp-master-$i.qcow2
done

for i in 0 1 2; do
virsh destroy ocp-worker-$i
virsh undefine ocp-worker-$i
rm -rf /home/sno/images/ocp-worker-$i.qcow2
done

for i in 0 1 2; do
virsh destroy ocp-infra-$i
virsh undefine ocp-infra-$i
rm -rf /home/sno/images/ocp-infra-$i.qcow2
done

~~~
