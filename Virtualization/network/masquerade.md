# Masquerade

## Inspect the VM and see how Masqeuade works

```bash

$ sh-5.1$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0@if59: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400 qdisc noqueue state UP group default
    link/ether 0a:58:0a:0a:00:33 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.10.0.51/23 brd 10.10.1.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::858:aff:fe0a:33/64 scope link
       valid_lft forever preferred_lft forever
3: k6t-eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400 qdisc noqueue state UP group default qlen 1000
    link/ether 02:00:00:00:00:00 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.1/24 brd 10.0.2.255 scope global k6t-eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::ff:fe00:0/64 scope link
       valid_lft forever preferred_lft forever
4: tap0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400 qdisc fq_codel master k6t-eth0 state UP group default qlen 1000
    link/ether a6:44:4b:f5:53:fc brd ff:ff:ff:ff:ff:ff
    inet6 fe80::a444:4bff:fef5:53fc/64 scope link
       valid_lft forever preferred_lft forever

sh-5.1$ ip r
default via 10.10.0.1 dev eth0
10.0.2.0/24 dev k6t-eth0 proto kernel scope link src 10.0.2.1
10.8.0.0/14 via 10.10.0.1 dev eth0
10.10.0.0/23 dev eth0 proto kernel scope link src 10.10.0.51
100.64.0.0/16 via 10.10.0.1 dev eth0
172.30.0.0/16 via 10.10.0.1 dev eth0

```

```
sh-5.1$ virsh list
Authorization not available. Check if polkit service is running or see debug message for more information.
 Id   Name                        State
-------------------------------------------
 1    default_rhel9-rose-bee-59   running


virsh dumpxml 1 | more
<Snip>
    <interface type='ethernet'>
      <mac address='02:9e:ed:00:00:00'/>
      <target dev='tap0' managed='no'/>
      <model type='virtio-non-transitional'/>
      <mtu size='1400'/>
      <alias name='ua-default'/>
      <rom enabled='no'/>
      <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
    </interface>


sh-5.1$ cat /sys/class/net/k6t-eth0/brif/tap0/

sh-5.1$ cat /sys/class/net/k6t-eth0/brif/tap0/
```

Node:

```bash
sh-5.1# ip netns exec $netns /bin/bash
[systemd]
Failed Units: 1
  NetworkManager-wait-online.service
[root@master03 /]# nft list table nat
table ip nat {
        chain prerouting {
                type nat hook prerouting priority dstnat; policy accept;
                iifname "eth0" counter packets 16 bytes 960 jump KUBEVIRT_PREINBOUND
        }

        chain input {
                type nat hook input priority srcnat; policy accept;
        }

        chain output {
                type nat hook output priority dstnat; policy accept;
                ip daddr 127.0.0.1 counter packets 0 bytes 0 dnat to 10.0.2.2
        }

        chain postrouting {
                type nat hook postrouting priority srcnat; policy accept;
                ip saddr 10.0.2.2 counter packets 192 bytes 14548 masquerade
                oifname "k6t-eth0" counter packets 20 bytes 1553 jump KUBEVIRT_POSTINBOUND
        }

        chain KUBEVIRT_PREINBOUND {
                counter packets 16 bytes 960 dnat to 10.0.2.2
        }

        chain KUBEVIRT_POSTINBOUND {
                ip saddr 127.0.0.1 counter packets 0 bytes 0 snat to 10.0.2.1
        }
}
```

So the traffic should be: Client -> external IP (Loadbalancer type service) -> Node -> service -> virt-launcher Pod -> VM
