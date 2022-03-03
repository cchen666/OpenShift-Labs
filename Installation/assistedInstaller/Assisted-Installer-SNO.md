# Deploy SNO using AI

## Download ISO

## Pre-create VM

~~~bash

$ virt-install -n ocp-sno \
--memory 32768 \
--os-variant=fedora-coreos-stable \
--vcpus=8  \
--accelerate  \
--cpu host-passthrough,cache.mode=passthrough  \
--disk path=/home/sno/images/ocp-sno.qcow2,size=120  \
--network network=ocp-dev,mac=02:01:00:00:00:31  \
--cdrom $IMAGE &

~~~
