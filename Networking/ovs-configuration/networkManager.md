# Network in NetworkManager Level

ovs-bridge -> ovs-port -> ovs-interface

## nmcli con

```bash
sh-4.4# nmcli con
NAME                UUID                                  TYPE           DEVICE
ovs-if-br-ex        5599ac68-35b8-4c6f-8f18-342d48bbb0aa  ovs-interface  br-ex
br-ex               b0f5201c-b389-464f-b7e7-e1683168be91  ovs-bridge     br-ex
ovs-if-phys0        6a7a7056-c9fe-4b30-aae1-6dc0caf1f019  ethernet       ens3
ovs-port-br-ex      829187d7-4ae6-45a2-9ee7-2b64d1b9ea66  ovs-port       br-ex
ovs-port-phys0      652a1bff-b41d-4d90-bc6a-179a3e8dddfd  ovs-port       ens3
```

* The ovs-interface has the L3 configuration, aka the IP address, the Gateway

```bash
sh-4.4# nmcli con show ovs-if-br-ex | grep IP
GENERAL.IP-IFACE:                       br-ex
IP4.ADDRESS[1]:                         192.168.3.171/16
IP4.ADDRESS[2]:                         169.254.169.2/29
IP4.ADDRESS[3]:                         192.168.0.7/32
IP4.GATEWAY:                            192.168.0.1
IP4.ROUTE[1]:                           dst = 0.0.0.0/0, nh = 192.168.0.1, mt = 48
IP4.ROUTE[2]:                           dst = 169.254.169.0/29, nh = 0.0.0.0, mt = 0
IP4.ROUTE[3]:                           dst = 169.254.169.1/32, nh = 0.0.0.0, mt = 0
IP4.ROUTE[4]:                           dst = 169.254.169.254/32, nh = 192.168.0.10, mt = 48
IP4.ROUTE[5]:                           dst = 172.30.0.0/16, nh = 169.254.169.4, mt = 0
IP4.ROUTE[6]:                           dst = 192.168.0.0/16, nh = 0.0.0.0, mt = 48
IP4.DNS[1]:                             10.11.5.19
IP4.DNS[2]:                             10.2.32.1
IP6.ADDRESS[1]:                         fe80::2f39:551d:a4ae:e732/64
IP6.GATEWAY:                            --
IP6.ROUTE[1]:                           dst = fe80::/64, nh = ::, mt = 1024
```

* The Ethernet ens3's master is ovs-port-phys0.

```bash
sh-4.4# nmcli con show ovs-if-phys0 | grep connection
connection.master:                      652a1bff-b41d-4d90-bc6a-179a3e8dddfd
connection.slave-type:                  ovs-port
```

* Then the rests are ovs-port
