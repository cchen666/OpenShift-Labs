# Install IPv4 Only Cluster using AI SaaS

## Create Cluster

~~~bash

$ aicli create cluster --paramfile files/ipv4.yml mycluster
$ aicli update cluster -P base_dns_domain=ocp.com mycluster
$ aicli update cluster -P network_type=OpenShiftSDN mycluster
~~~

## Download ISO

~~~bash


$ aicli create iso mycluster # Deprecated API to get ISO link but you can directly download the ISO
$ cd /home/sno/images
$ aicli download iso mycluster

~~~

## Create VMs

~~~bash

$ IMAGE=<downloaded ISO>

$ for i in 0 1 2; do \
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

## Launch the Installation

~~~bash

# We can cannot specify api_vip when creating the cluster now but can only update the cluster later
# Being addressed in https://github.com/openshift/assisted-service/pull/3258

$ aicli update cluster -P api_vip=192.168.123.251 mycluster
$ aicli update cluster -P ingress_vip=192.168.123.11 mycluster
$ aicli update host master-0 -P extra_args="--append-karg=ip=dhcp6"

$ aicli start cluster mycluster

~~~

## Known Issues

~~~bash
failed executing nsenter [--target 1 --cgroup --mount --ipc --pid -- coreos-installer install --insecure -i /opt/install-dir/master-7ab24253-9f06-470a-b26f-a83e5c382df8.ign --append-karg iommu pt --append-karg intel_iommu on --append-karg ip=enp1s0:dhcp /dev/vda], Error exit status 1, LastOutput \\\"... ument 'on' which wasn't expected, or isn't valid in this context\\n\\nUSAGE:\\n    coreos-installer install <device> --append-karg <arg>... --ignition-file <path> --insecure\\n\\nFor more information try --help\\\"\" request_id=29182758-dec4-4fbd-84d6-0159a92aff1d\n\n\nstderr:\nexit status 1\n" file="step_processor.go:102" request_id=dcf48e3d-74b8-40a8-81a4-4cca7b49fe52
~~~
