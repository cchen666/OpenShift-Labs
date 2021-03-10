# DRAFT: Agent-Based Assisted Installer

## Generate ISO

~~~bash

$ ./openshift-install --dir install agent create image
INFO The rendezvous host IP (node0 IP) is 192.168.123.80
INFO Extracting base ISO from release payload
INFO Base ISO obtained from release and cached at /root/.cache/agent/image_cache/coreos-x86_64.iso
INFO Consuming Agent Config from target directory
INFO Consuming Install Config from target directory

~~~

## Boot VM

~~~bash

$ virt-install -n sno412 \
--memory 16384 \
--vcpus=8 \
--accelerate \
--cpu host-passthrough \
--disk path=/home/sno/sno412.qcow2,size=120 \
--network network=ocp-dev,mac=02:01:00:00:00:66 \
--cdrom /home/sno/coreos-x86_64.iso

~~~

## Watch the Installation Process

~~~bash

$   journalctl --field _SYSTEMD_UNIT
$ journalctl -u assisted-service -f
$ journalctl -u start-cluster-installation

~~~
