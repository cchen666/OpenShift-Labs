# Assisted Installer on KVM Host

## ocp-dev net

~~~bash
On Host create such virtual network:

# virsh net-dumpxml ocp-dev
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
~~~

## Navigate to assited installer console

~~~bash
<https://console.redhat.com/openshift/assisted-installer/clusters/~new>
Cluster Name: mycluster
Base Domain: ocp.com
Next
Generate Discovery ISO -> Copy your hosts ssh public key -> Generate Discovery ISO -> Download the ISO and save it
~~~

## Install Haproxy LoadBalancer VM

~~~bash

virt-install -n ocp-haproxy \
--memory 1024 \
--os-variant=fedora-coreos-stable \
--vcpus=1  \
--accelerate  \
--cpu host-passthrough,cache.mode=passthrough  \
--disk path=/home/sno/images/ocp-haproxy.qcow2,size=120  \
--network network=ocp-dev,mac=02:01:00:00:00:50  \
--cdrom rhel8u4.iso

# yum install haproxy

# cat /etc/haproxy/haproxy.cfg 
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
	server  	worker-0.mycluster.ocp.com 192.168.123.9:80 check
 
backend router-https-traffic
	balance source
	mode tcp
	server  	worker-0.mycluster.ocp.com 192.168.123.9:80 check
 
backend k8s-api-server
	balance source
	mode tcp
	server  	master-0.mycluster.ocp.com 192.168.123.6:6443 check
	server  	master-1.mycluster.ocp.com 192.168.123.7:6443 check
	server  	master-2.mycluster.ocp.com 192.168.123.8:6443 check
 
backend machine-config-server
	balance source
	mode tcp
	server  	master-0.mycluster.ocp.com 192.168.123.6:22623 check
	server  	master-1.mycluster.ocp.com 192.168.123.7:22623 check
	server  	master-2.mycluster.ocp.com 192.168.123.8:22623 check

# setenforce 0
# systemctl restart haproxy
~~~



## Install master and worker VMs

~~~bash
IMAGE=/home/sno/images/<image.iso>
for i in 0 1 2; do
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

IMAGE=/home/sno/images/<image.iso>
for i in 0 1; do
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
~~~

## Install the Cluster in Assited Installer Console

~~~bash
The 5 hosts should be discovered and assign 3 masters + 2 workers and then press Install
~~~
