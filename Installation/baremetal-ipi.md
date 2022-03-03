# Baremetal IPI Installation

## Pre-create VMs

~~~bash
$ virt-install --name=ocp4-master0 --vcpus=4 --ram=16384 \
--disk path=/home/sno/images/master0.qcow2,size=120 \
--os-variant rhel8.0 --network bridge=provisioning,model=virtio \
--network bridge=baremetal,model=virtio \
--boot uefi,nvram_template=/usr/share/OVMF/OVMF_VARS.fd,menu=on  \
--print-xml > ${KVM_DIRECTORY}/ocp4-master0.xml

$ virt-install --name=ocp4-worker0 --vcpus=4 --ram=8192 \
--disk path=/home/sno/images/worker0.qcow2,size=120 \
--os-variant rhel8.0 --network bridge=provisioning,model=virtio \
--network bridge=baremetal,model=virtio \
--boot uefi,nvram_template=/usr/share/OVMF/OVMF_VARS.fd,menu=on  \
--print-xml > ${KVM_DIRECTORY}/ocp4-worker0.xml

~~~

<https://openshift-kni.github.io/baremetal-deploy/latest/Deployment>
