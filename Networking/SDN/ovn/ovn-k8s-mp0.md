# What does ovn-k8s-mp0 do

ovn-k8s-mp0 is a management port with .2 IP. It is a port attached to br-int. It will be used
in the following scenarios:

1. Local Pod to local Node
2. Local node to local Pod

In other words, it won't be used in the following scenarios:

1. Pods to Pods
2. Pods to Internet

## Verification

1. Login to the one of the worker nodes and start the tcpdump on `ovn-k8s-mp0`:

    ```bash

    $ oc debug node/cchen414-fzb7j-worker-0-nvmxn
    sh-4.4# tcpdump -i ovn-k8s-mp0 -nnn host 10.131.0.147
    dropped privs to tcpdump
    tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
    listening on ovn-k8s-mp0, link-type EN10MB (Ethernet), capture size 262144 bytes

    ```

    ```bash

    $ oc get pods
    NAME                          READY   STATUS      RESTARTS       AGE     IP             NODE                            NOMINATED NODE   READINESS GATES
    busybox-deployment-5-np57c    1/1     Running     67 (18m ago)   2d19h   10.131.0.147   cchen414-fzb7j-worker-0-nvmxn   <none>           <none>

    ```

2. Ping the node cchen414-fzb7j-worker-0-nvmxn IP

    ```bash
    $ oc rsh busybox-deployment-5-np57c
    sh-4.4$ ping 192.168.2.82
    PING 192.168.2.82 (192.168.2.82) 56(84) bytes of data.
    64 bytes from 192.168.2.82: icmp_seq=1 ttl=64 time=1.14 ms
    64 bytes from 192.168.2.82: icmp_seq=2 ttl=64 time=0.541 ms
    64 bytes from 192.168.2.82: icmp_seq=3 ttl=64 time=0.163 ms
    64 bytes from 192.168.2.82: icmp_seq=4 ttl=64 time=0.096 ms

    ```

    Verify the tcpdump console

    ```bash
    03:00:32.307132 IP 10.131.0.147 > 192.168.2.82: ICMP echo request, id 2, seq 1, length 64
    03:00:32.307172 ARP, Request who-has 10.131.0.147 tell 10.131.0.2, length 28
    03:00:32.307302 ARP, Reply 10.131.0.147 is-at 0a:58:0a:83:00:93, length 28
    03:00:32.307308 IP 192.168.2.82 > 10.131.0.147: ICMP echo reply, id 2, seq 1, length 64
    03:00:33.308233 IP 10.131.0.147 > 192.168.2.82: ICMP echo request, id 2, seq 2, length 64
    03:00:33.308260 IP 192.168.2.82 > 10.131.0.147: ICMP echo reply, id 2, seq 2, length 64
    03:00:34.349018 IP 10.131.0.147 > 192.168.2.82: ICMP echo request, id 2, seq 3, length 64
    03:00:34.349062 IP 192.168.2.82 > 10.131.0.147: ICMP echo reply, id 2, seq 3, length 64
    03:00:35.372941 IP 10.131.0.147 > 192.168.2.82: ICMP echo request, id 2, seq 4, length 64
    03:00:35.372969 IP 192.168.2.82 > 10.131.0.147: ICMP echo reply, id 2, seq 4, length 64
    ```

3. Ping the 8.8.8.8 or other Pod IPs but no tcpdump captured

   ```bash
    sh-4.4$ ping 8.8.8.8
    PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
    64 bytes from 8.8.8.8: icmp_seq=1 ttl=108 time=11.5 ms
    64 bytes from 8.8.8.8: icmp_seq=2 ttl=108 time=9.16 ms
    64 bytes from 8.8.8.8: icmp_seq=3 ttl=108 time=8.25 ms
    ^C
    --- 8.8.8.8 ping statistics ---
    3 packets transmitted, 3 received, 0% packet loss, time 2003ms
    rtt min/avg/max/mdev = 8.247/9.642/11.520/1.381 ms
    sh-4.4$ ping 10.128.3.230
    PING 10.128.3.230 (10.128.3.230) 56(84) bytes of data.
    64 bytes from 10.128.3.230: icmp_seq=1 ttl=62 time=1.97 ms
    64 bytes from 10.128.3.230: icmp_seq=2 ttl=62 time=1.04 ms
    64 bytes from 10.128.3.230: icmp_seq=3 ttl=62 time=0.500 ms
    64 bytes from 10.128.3.230: icmp_seq=4 ttl=62 time=0.380 ms
    ^C
    --- 10.128.3.230 ping statistics ---
    4 packets transmitted, 4 received, 0% packet loss, time 3014ms
    rtt min/avg/max/mdev = 0.380/0.972/1.973/0.628 ms

    # tcpdump shows nothing
   ```

## Why

1. ovn-k8s-mp0 is a port on br-int

   ```bash
   sh-5.1# ovs-vsctl show
    4b7a3730-251e-4623-a948-5e92de0369af
        Bridge br-int
            fail_mode: secure
            datapath_type: system
    <Snip>
            Port ovn-k8s-mp0
            Interface ovn-k8s-mp0
                type: internal

   ```

2. Checking the IPs and Route table on the node. The ovn-k8s-mp0 will be assigned with the IP
   with .2 of the Pod subnet (10.131.0.0/24) on the particular node

   ```bash
    sh-5.1# ifconfig ovn-k8s-mp0
    ovn-k8s-mp0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 7850
            inet 10.131.0.2  netmask 255.255.254.0  broadcast 10.131.1.255
            inet6 fe80::507f:8bff:fe03:9026  prefixlen 64  scopeid 0x20<link>
            ether 52:7f:8b:03:90:26  txqueuelen 1000  (Ethernet)
            RX packets 80023052  bytes 36830989503 (34.3 GiB)
            RX errors 0  dropped 0  overruns 0  frame 0
            TX packets 93668355  bytes 73699504090 (68.6 GiB)
            TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

    sh-5.1# route -n
    Kernel IP routing table
    Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
    0.0.0.0         192.168.0.1     0.0.0.0         UG    48     0        0 br-ex
    10.128.0.0      10.131.0.1      255.252.0.0     UG    0      0        0 ovn-k8s-mp0
    10.131.0.0      0.0.0.0         255.255.254.0   U     0      0        0 ovn-k8s-mp0
    169.254.169.0   0.0.0.0         255.255.255.248 U     0      0        0 br-ex
    169.254.169.1   0.0.0.0         255.255.255.255 UH    0      0        0 br-ex
    169.254.169.3   10.131.0.1      255.255.255.255 UGH   0      0        0 ovn-k8s-mp0
    169.254.169.254 192.168.0.10    255.255.255.255 UGH   48     0        0 br-ex
    172.30.0.0      169.254.169.4   255.255.0.0     UG    0      0        0 br-ex
    192.168.0.0     0.0.0.0         255.255.0.0     U     48     0        0 br-ex
   ```

3. OVN DB explore - the source of everything

* NBDB shows as follows. So ovn-k8s-mp0 is a virtual port on node logical switch

   ```bash
   $ ovn-nbctl show
   switch d6db4c6a-720a-47d5-a2ae-f2a25a527988 (cchen414-fzb7j-worker-0-nvmxn)

       port k8s-cchen414-fzb7j-worker-0-nvmxn
        addresses: ["52:7f:8b:03:90:26 10.131.0.2"]
   ```

* SBDB logical flows

  ```bash
  $ ovn-sbctl lflow-list

       714   table=21(ls_in_arp_rsp      ), priority=100  , match=(arp.tpa == 10.131.0.2 && arp.op == 1 && inport == "k8s-cchen414-fzb7j-worker-0-nvmxn"),         action=(next;)

       787   table=27(ls_in_l2_lkup      ), priority=50   , match=(eth.dst == 52:7f:8b:03:90:26), action=(outport = "k8s-cchen414-fzb7j-worker-0-nvmxn"; output;)


   # 52:7f:8b:03:90:26 is the MAC of ovn-k8s-mp0
  ```

* Checking ovn-trace. It specifies the src from the Pod and dst as the node IP

    ```bash
    $ ovn-trace --no-leader-only  --db unix:/var/run/ovn/ovnsb_db.sock cchen414-fzb7j-worker-0-nvmxn 'inport=="test-dc_busybox-deployment-5-np57c" && eth.src==0a:58:0a:83:00:93 && eth.dst==0a:58:0a:83:00:01 && ip4.src==10.131.0.147 && ip4.dst==192.168.2.82 && ip.ttl==64 && tcp.dst==80 && tcp.src==52888'

    ```

    The datapath order that passes:

    ```txt
    ingress(dp="cchen414-fzb7j-worker-0-nvmxn", inport="test-dc_busybox-deployment-5-np57c") [1]
    egress(dp="cchen414-fzb7j-worker-0-nvmxn", inport="test-dc_busybox-deployment-5-np57c",  outport="stor-cchen414-fzb7j-worker-0-nvmxn") [2]
    ingress(dp="ovn_cluster_router", inport="rtos-cchen414-fzb7j-worker-0-nvmxn")[3]
    egress(dp="ovn_cluster_router", inport="rtos-cchen414-fzb7j-worker-0-nvmxn", outport="rtos-cchen414-fzb7j-worker-0-nvmxn") [4]
    ingress(dp="cchen414-fzb7j-worker-0-nvmxn", inport="stor-cchen414-fzb7j-worker-0-nvmxn")[5]
    egress(dp="cchen414-fzb7j-worker-0-nvmxn", inport="stor-cchen414-fzb7j-worker-0-nvmxn", outport="k8s-cchen414-fzb7j-worker-0-nvmxn")[6]

    ```

    So in short, the packet left from the Pod and reached to LS [1], then leave the LS and reache
    to LR [2]. The LR receives the packet in [3], and send the packet back to LS [4]. The packet
    reached to LS again in [5], and then finally sent through k8s-cchen414-fzb7j-worker-0-nvmxn
    (ovn-k8s-mp0) port in [6].

* Where the key

  The LR has a table 15, where to determine the destination IP address. If the dst is the node
  itself, it will set reg0 to the `ovn-k8s-mp0` IP address, outport and flags.loopback = 1.

  ```txt
  Datapath: "ovn_cluster_router" (1dd6ab62-b915-44ee-94fc-d89a1f03644a)  Pipeline: egress
    table=15(lr_in_policy       ), priority=1004 , match=(inport == "rtos-cchen414-fzb7j-worker-0-nvmxn" && ip4.dst == 192.168.2.82 /* cchen414-fzb7j-worker-0-nvmxn */), action=(reg0 = 10.131.0.2; reg1 = 10.131.0.1; eth.src = 0a:58:0a:83:00:01; outport = "rtos-cchen414-fzb7j-worker-0-nvmxn"; flags.loopback = 1; reg8[0..15] = 0; next;)
  ```

   Further in table 17:

   ```txt

     table=17(lr_in_arp_resolve  ), priority=100  , match=(outport == "rtos-cchen414-fzb7j-worker-0-nvmxn" && reg0 == 10.131.0.2), action=(eth.dst = 52:7f:8b:03:90:26; next;)

   ```

   Then the node LS receives the packets and matches table 27 of LS, which sets the outport
   to k8s-cchen414-fzb7j-worker-0-nvmxn, aka `ovn-k8s-mp0`

   ```txt

   ingress(dp="cchen414-fzb7j-worker-0-nvmxn", inport="stor-cchen414-fzb7j-worker-0-nvmxn")
     27. ls_in_l2_lkup (northd.c:10542): eth.dst == 52:7f:8b:03:90:26, priority 50, uuid 462957d9
     outport = "k8s-cchen414-fzb7j-worker-0-nvmxn";

   ```

* Routing Table for ovn_cluster_router

  ```bash
  sh-5.1# ovn-nbctl lr-route-list ovn_cluster_router
  IPv4 Routes
  Route Table <main>:
                100.64.0.2                100.88.0.2 dst-ip
                100.64.0.3                100.88.0.3 dst-ip
                100.64.0.4                100.88.0.4 dst-ip
                100.64.0.5                100.64.0.5 dst-ip
                100.64.0.6                100.88.0.6 dst-ip
              10.128.0.0/23                100.88.0.2 dst-ip
              10.128.2.0/23                100.88.0.6 dst-ip
              10.129.0.0/23                100.88.0.3 dst-ip
              10.130.0.0/23                100.88.0.4 dst-ip
              10.131.0.0/23                100.64.0.5 src-ip
              10.128.0.0/14                100.64.0.5 src-ip
  ```
