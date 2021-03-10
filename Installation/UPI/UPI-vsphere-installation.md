# VSPhere UPI Installation

## Create Manifests

~~~bash

$ openshift-install create manifests --dir=install

$ cat <<EOF > install/manifests/cluster-network-03-config.yml
apiVersion: operator.openshift.io/v1
kind: Network
metadata:
  name: cluster
spec:
  defaultNetwork:
    openshiftSDNConfig:
      vxlanPort: 4800
EOF

$ rm -f install/openshift/99_openshift-cluster-api_master-machines-*.yaml openshift/99_openshift-cluster-api_worker-machineset-*.yaml

~~~

## Generate Ignition Files

~~~bash

$ openshift-install create ignition-configs --dir=install

~~~

## Generate base64 Ignition Files

~~~bash

$ cat <<EOF > install/merge-bootstrap.ign

{
  "ignition": {
    "config": {
      "merge": [
        {
          "source": "http://10.72.94.119:8080/openshift/bootstrap.ign",
          "verification": {}
        }
      ]
    },
    "timeouts": {},
    "version": "3.1.0"
  },
  "networkd": {},
  "passwd": {},
  "storage": {},
  "systemd": {}
}

EOF

base64 -w0 install/master.ign > install/master.64
base64 -w0 install/worker.ign > install/worker.64
base64 -w0 install/merge-bootstrap.ign > install/merge-bootstrap.64

$ mkdir /var/www/html/openshift
$ cp install/bootstrap.ign /var/www/html/openshift/
$ chmod 777 /var/www/html/openshift
$ chmod 777 /var/www/html/openshift/bootstrap.ign

~~~

## Install govc Tool

~~~bash

$ curl -L -o - "https://github.com/vmware/govmomi/releases/latest/download/govc_$(uname -s)_$(uname -m).tar.gz" | tar -C /usr/local/bin -xvzf - govc

$ export GOVC_URL=vmware.rhts.gsslab.pek2.redhat.com
$ export GOVC_USERNAME=administrator@vsphere.local
$ export GOVC_PASSWORD=<OpenShift>
$ export GOVC_DATACENTER=Datacenter
$ export GOVC_INSECURE=true

~~~

## Create VM in VSphere

1. Download ISO from <https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/>
2. Deploy OVA File to a template
3. Clone template to Virtual Machine - bootstrap, master-[0-2], worker-[0-1]

~~~bash
$ Folder=4.10.3
$ Template=template-rhcos-4.10.3
$ DNS=10.72.94.119
$ govc vm.clone -vm $Template -c=4 -m=8192 -folder=$Folder -host=vmware-host01.rhts.gsslab.pek2.redhat.com -on=false -ds=datastore1 bootstrap &
$ for i in 0 1 2
do
  govc vm.clone \
  -vm $Template \
  -c=8 -m=16384 \
  -folder=$Folder \
  -host=vmware-host0`expr $i + 2`.rhts.gsslab.pek2.redhat.com \
  -on=false \
  -ds=datastore`expr $i + 2` \
  master$i &
done

$ for i in 0 1
do
  govc vm.clone \
  -vm $Template \
  -c=4 -m=8192 \
  -folder=$Folder \
  -host=vmware-host0`expr $i + 2`.rhts.gsslab.pek2.redhat.com \
  -on=false \
  -ds=datastore`expr $i + 2` \
  worker$i &
done
~~~

## Inject guestinfo to Nodes Static IPs

~~~bash

$ MASTER_IGN=`cat install/master.64`
$ WORKER_IGN=`cat install/worker.64`
$ BOOTSTRAP_IGN=`cat install/merge-bootstrap.64`

~~~

### Static IP

~~~bash

# Bootstrap; Add it to a loop to make copy easier
for i in 0; do
  IPCFG="ip=10.72.94.248::10.72.94.254:255.255.255.0:bootstrap.vmware.cchen.work::none nameserver=$DNS"
  govc vm.change -vm bootstrap -e "guestinfo.afterburn.initrd.network-kargs=${IPCFG}"
  govc vm.change -vm bootstrap -e "guestinfo.ignition.config.data=${BOOTSTRAP_IGN}"
  govc vm.change -vm bootstrap -e "guestinfo.ignition.config.data.encoding=base64"
  govc vm.change -vm bootstrap -e "guestinfo.hostname=bootstrap.vmware.cchen.work"
  govc vm.change -vm bootstrap -e "disk.EnableUUID=TRUE"
done

# Master
$ for i in 0 1 2
do
  IPCFG="ip=10.72.94.23$i::10.72.94.254:255.255.255.0:master$i.vmware.cchen.work::none nameserver=$DNS"
  govc vm.change -vm master$i -e "guestinfo.afterburn.initrd.network-kargs=${IPCFG}"
  govc vm.change -vm master$i -e "guestinfo.ignition.config.data=${MASTER_IGN}"
  govc vm.change -vm master$i -e "guestinfo.ignition.config.data.encoding=base64"
  govc vm.change -vm master$i -e "guestinfo.hostname=master$i.vmware.cchen.work"
  govc vm.change -vm master$i -e "disk.EnableUUID=TRUE"
done

# Worker
$ for i in 0 1
do
  IPCFG="ip=10.72.94.24$i::10.72.94.254:255.255.255.0:worker$i.vmware.cchen.work::none nameserver=$DNS"
  govc vm.change -vm worker$i -e "guestinfo.afterburn.initrd.network-kargs=${IPCFG}"
  govc vm.change -vm worker$i -e "guestinfo.ignition.config.data=${WORKER_IGN}"
  govc vm.change -vm worker$i -e "guestinfo.ignition.config.data.encoding=base64"
  govc vm.change -vm worker$i -e "guestinfo.hostname=worker$i"
  govc vm.change -vm worker$i -e "disk.EnableUUID=TRUE"
done

~~~

### DHCP

~~~bash

# Bootstrap
govc vm.change -vm bootstrap -e "guestinfo.ignition.config.data=${BOOTSTRAP_IGN}"
govc vm.change -vm bootstrap -e "guestinfo.ignition.config.data.encoding=base64"
govc vm.change -vm bootstrap -e "disk.EnableUUID=TRUE"

# Master
$ for i in 0 1 2
do
govc vm.change -vm master$i -e "guestinfo.ignition.config.data=${MASTER_IGN}"
govc vm.change -vm master$i -e "guestinfo.ignition.config.data.encoding=base64"
govc vm.change -vm master$i -e "disk.EnableUUID=TRUE"
done

# Worker
$ for i in 0 1
do
govc vm.change -vm worker$i -e "guestinfo.ignition.config.data=${WORKER_IGN}"
govc vm.change -vm worker$i -e "guestinfo.ignition.config.data.encoding=base64"
govc vm.change -vm worker$i -e "guestinfo.hostname=worker$i"
govc vm.change -vm worker$i -e "disk.EnableUUID=TRUE"
done

~~~

## Start the Nodes

~~~bash
$ govc vm.power -on bootstrap master0 master1 master2
~~~

## Stop and Delete Nodes

~~~bash
govc vm.power -off bootstrap master0 master1 master2 worker0 worker1
govc vm.destroy bootstrap

for i in 0 1 2
do
govc vm.destroy master$i
done

for i in 0 1
do
govc vm.destroy worker$i
done
~~~

## Remove CD-ROM

~~~bash
$  govc device.ls -vm=cchen-mirror-registry
ide-200       VirtualIDEController       IDE 0
ide-201       VirtualIDEController       IDE 1
ps2-300       VirtualPS2Controller       PS2 controller 0
pci-100       VirtualPCIController       PCI controller 0
sio-400       VirtualSIOController       SIO controller 0
keyboard-600  VirtualKeyboard            Keyboard
pointing-700  VirtualPointingDevice      Pointing device; Device
video-500     VirtualMachineVideoCard    Video card
vmci-12000    VirtualMachineVMCIDevice   Device on the virtual machine PCI bus that provides support for the virtual machine communication interface
pvscsi-1000   ParaVirtualSCSIController  VMware paravirtual SCSI
cdrom-3000    VirtualCdrom               ISO [datastore1] ISO/rhel-8.3-x86_64-dvd.iso
disk-1000-0   VirtualDisk                125,829,120 KB
ethernet-1    VirtualVmxnet3             VM Network
disk-1000-1   VirtualDisk                104,857,600 KB

$ govc device.remove -vm=cchen-mirror-registry cdrom-3000
~~~
