# Deploy SNO using AI

## Download ISO

~~~bash

$ OCP_VERSION=4.10.10
$ curl -k https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OCP_VERSION/openshift-install-linux.tar.gz > openshift-install-linux.tar.gz
$ tar zxvf openshift-install-linux.tar.gz
$ chmod +x openshift-install
$ ISO_URL=$(./openshift-install coreos print-stream-json | grep location | grep x86_64 | grep iso | cut -d\" -f4)
$ wget -O /home/sno/images/rhcos-410.84-live.iso $ISO_URL
~~~

## Customize

~~~bash
./openshift-install --dir=ocp create single-node-ignition-config
cp ocp/bootstrap-in-place-for-live-iso.ign iso.ign
IMAGE=rhcos-410.84-live.iso
arg1="console=ttyS0"
arg2="console=ttyS0,115200n8"
arg3="coreos.autologin=ttyS0"
arg4="ip=192.168.124.133::192.168.124.1:255.255.255.0:::none nameserver=192.168.124.1"
alias coreos-installer='podman run --privileged --rm -v /dev:/dev -v /run/udev:/run/udev -v $PWD:/data -w /data quay.io/coreos/coreos-installer:release'
coreos-installer iso customize $IMAGE --dest-karg-append="$arg1" --dest-karg-append="$arg2" --dest-karg-append="$arg3" --dest-karg-append="$arg4" --live-karg-append="$arg1" --live-karg-append="$arg2" --live-karg-append="$arg3" --live-karg-append="$arg4"
coreos-installer iso ignition embed -fi iso.ign rhcos-410.84-live.iso
~~~

## Pre-create VM

~~~bash

$ IMAGE=/home/sno/images/rhcos-410.84-live.iso
$ virt-install -n ocp-sno \
--memory 32768 \
--os-variant=fedora-coreos-stable \
--vcpus=8  \
--accelerate  \
--cpu host-passthrough,cache.mode=passthrough  \
--disk path=/home/sno/images/ocp-sno.qcow2,size=120  \
--network network=ocp-sno \
--cdrom $IMAGE &

~~~
