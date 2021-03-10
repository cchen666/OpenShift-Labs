# Single Node OpenShift

## Basic RHEL-8 Host Configurations

~~~bash
$ cd /etc/yum.repos.d/
$ for i in *.repo;do mv $i $i.bak;done

$ subscription-manager register --username rhn-support-cchen --force
$ subscription-manager attach --pool=8a85f9833e1404a9013e3cddf95a0599

$ yum update
$ yum install qemu-kvm-* libvirt-client libvirt wget virt-install -y
$ systemctl start libvirtd
$ systemctl enable libvirtd
$ mkdir /home/sno/images -p
~~~

## Virtualization Related Configurations

~~~bash
# cat << EOF > ocp-storage.xml
<pool type="dir">
        <name>ocp_disk</name>
        <target>
          <path>/home/sno/images</path>
        </target>
</pool>

EOF

# virsh pool-define ocp-storage.xml
# virsh pool-start ocp_disk
# virsh pool-autostart ocp_disk

# cat << EOF > ocp-net.xml
<network xmlns:dnsmasq="http://libvirt.org/schemas/network/dnsmasq/1.0">
  <name>ocp-dev</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr1' stp='on' delay='0'/>
  <ip address='192.168.123.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.123.2' end='192.168.123.254'/>
      <host mac="02:01:00:00:00:66" name="node.mycluster.ocp.com" ip="192.168.123.5"/>
    </dhcp>
  </ip>
  <dns>
    <host ip="192.168.123.5"><hostname>api.mycluster.ocp.com</hostname></host>
  </dns>
  <dnsmasq:options>
    <!-- fix for the 5s timeout on DNS -->
    <!-- see https://www.math.tamu.edu/~comech/tools/linux-slow-dns-lookup/ -->
    <dnsmasq:option value="auth-server=mycluster.ocp.com,"/><!-- yes, there is a trailing coma -->
    <dnsmasq:option value="auth-zone=mycluster.ocp.com"/>
    <!-- Wildcard route -->
    <dnsmasq:option value="host-record=lb.mycluster.ocp.com,192.168.123.5"/>
    <dnsmasq:option value="cname=*.apps.mycluster.ocp.com,lb.mycluster.ocp.com"/>
  </dnsmasq:options>
</network>

EOF

# virsh net-define ocp-net.xml
# virsh net-start ocp-dev
# virsh net-autostart ocp-dev
~~~

## Download discovery_image_mycluster.iso from [cloud.redhat.com](cloud.redhat.com)

## Create All-in-One OpenShift Node

~~~bash
# virt-install -n ocp-dev \
--memory 51200 \
--os-variant=fedora-coreos-stable \
--vcpus=10 \
--accelerate \
--cpu host-passthrough,cache.mode=passthrough \
--disk path=/home/sno/images/ocp-dev.qcow2,size=500 \
--network network=ocp-dev,mac=02:01:00:00:00:66 \
--cdrom /home/sno/images/discovery_image_mycluster.iso
~~~
