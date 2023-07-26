# Agent-Based Assisted Installer

## Generate ISO

```bash

$ ./openshift-install --dir install agent create image
INFO The rendezvous host IP (node0 IP) is 192.168.122.80
INFO Extracting base ISO from release payload
INFO Base ISO obtained from release and cached at /root/.cache/agent/image_cache/coreos-x86_64.iso
INFO Consuming Agent Config from target directory
INFO Consuming Install Config from target directory

```

## Copy Installation Files

```bash

$ mkdir install
$ cp files/agent-config.yaml files/install-config.yaml install
$ cp install/agent.x86_64.iso /home/sno/images
$ IMAGE=/home/sno/images/agent.x86_64.iso

```

## Boot VM

```bash

$ for i in 0 1 2; do virt-install -n ocp-master-$i --memory 16384 --os-variant=fedora-coreos-stable --vcpus=4  --accelerate  --cpu host-passthrough,cache.mode=passthrough  --disk path=/home/sno/images/ocp-master-$i.qcow2,size=120  --network network=default,mac=02:02:00:00:00:8$i  --cdrom $IMAGE & done

```

## Watch the Installation Process

```bash

$ journalctl --field _SYSTEMD_UNIT
$ journalctl -u assisted-service -f
$ journalctl -u start-cluster-installation

```
