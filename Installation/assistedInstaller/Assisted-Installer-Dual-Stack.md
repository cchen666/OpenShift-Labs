# Install Dual-Stack Cluster using AI SaaS

## Create Cluster

~~~bash

$ $ aicli create cluster --paramfile files/dual-stack.yml mycluster

~~~

## Create VMs

~~~bash

for i in 0 1 2; do \
virt-install \
-n ocp-master-$i \
--memory 16384 \
--os-variant=fedora-coreos-stable \
--vcpus=4  \
--accelerate  \
--cpu host-passthrough,cache.mode=passthrough  \
--disk path=/home/sno/images/ocp-master-$i.qcow2,size=120  \
--network network=ocp-dev,mac=02:01:00:00:00:6$i \
--cdrom $IMAGE & \
done

~~~

## Finish the Installation in WebUI

## Verification

~~~bash

$ oc describe network

<Snip>

Status:
  Cluster Network:
    Cidr:               10.128.0.0/14
    Host Prefix:        23
    Cidr:               fd01::/48
    Host Prefix:        64
  Cluster Network MTU:  1400
  Network Type:         OVNKubernetes
  Service Network:
    172.30.0.0/16
    fd02::/112
Events:  <none>

~~~
