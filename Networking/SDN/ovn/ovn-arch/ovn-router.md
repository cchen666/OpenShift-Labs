# OVN Router in Interconnet mode

## Basic Installation

```bash

$ oc get nodes
NAME                            STATUS   ROLES                  AGE   VERSION
cchen414-fzb7j-master-0         Ready    control-plane,master   76d   v1.27.10+28ed2d7
cchen414-fzb7j-master-1         Ready    control-plane,master   76d   v1.27.10+28ed2d7
cchen414-fzb7j-master-2         Ready    control-plane,master   76d   v1.27.10+28ed2d7
cchen414-fzb7j-worker-0-nvmxn   Ready    worker                 76d   v1.27.10+28ed2d7
cchen414-fzb7j-worker-0-qrmvn   Ready    worker                 53d   v1.27.10+28ed2d7

```

## ovn_cluster_router

* Check the routing table first

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

* 100.64.0.2 100.88.0.2 dst-ip

  * Lets first see what is 100.64 IP address. Since this is Interconnect mode, we see the 100.64.0.5 is a port on Gateway Router, which points to join switch.

    ```bash
    sh-5.1# ovn-nbctl show | grep 100.64 -B2
        port rtoj-GR_cchen414-fzb7j-worker-0-nvmxn
            mac: "0a:58:64:40:00:05"
            networks: ["100.64.0.5/16"]
    --
        nat 0347cb17-0436-4c31-9507-97d84cff3178
            external ip: "192.168.2.82"
            logical ip: "100.64.0.5"
    --
        port rtoj-ovn_cluster_router
            mac: "0a:58:64:40:00:01"
            networks: ["100.64.0.1/16"]
    ```

  * Then check what is 100.88. As the following shows, it is a port on ovn_cluster_router, which points to transit switch.

    ```bash

    switch d9f1fe52-ddf3-4465-948c-d0ff0495f658 (transit_switch)
        port tstor-cchen414-fzb7j-master-0
            type: remote
            addresses: ["0a:58:64:58:00:02 100.88.0.2/16"]
        port tstor-cchen414-fzb7j-master-2
            type: remote
            addresses: ["0a:58:64:58:00:04 100.88.0.4/16"]
        port tstor-cchen414-fzb7j-master-1
            type: remote
            addresses: ["0a:58:64:58:00:03 100.88.0.3/16"]
        port tstor-cchen414-fzb7j-worker-0-qrmvn
            type: remote
            addresses: ["0a:58:64:58:00:06 100.88.0.6/16"]
        port tstor-cchen414-fzb7j-worker-0-nvmxn
            type: router
            router-port: rtots-cchen414-fzb7j-worker-0-nvmxn
    --
    router 9158237b-b350-4e36-9014-3c3e64d09dfe (ovn_cluster_router)
        port rtots-cchen414-fzb7j-worker-0-nvmxn
            mac: "0a:58:64:58:00:05"
            networks: ["100.88.0.5/16"]
    ```

* Summary: 100.64.0.2 100.88.0.2 dst-ip means, if the dest IP is 100.64.0.2, the next hop is 100.88.0.2. It simply means, if the dest IP is the IP of ovn_cluster_router, then the next hop should go to transit switch. This is easy to understand because the 100.64.0.3 (for example) is on other node. The exception is for its own 100.64.0.5, where the next hop is his own IP. Traffic towards to other node's Pod subnets will have next hop as the corresponding 10.88.0.X IP. The exception is, if the traffic is generated within its own node, then the routing table will use src-ip to determine that. In this example, the next hop for this worker node's Pod is 100.64.0.5, which is its own IP, not 10.88.0.X. If the Pod traffic is targeting other node's Pod, then the routing table will point the next hop to go through transit switch and reaches to other node's ovn_cluster_router port, which holds 10.88.0.X.

## Gateway Router

```bash

sh-5.1# ovn-nbctl lr-route-list GR_cchen414-fzb7j-worker-0-nvmxn
IPv4 Routes
Route Table <main>:
         169.254.169.0/29             169.254.169.4 dst-ip rtoe-GR_cchen414-fzb7j-worker-0-nvmxn
            10.128.0.0/14                100.64.0.1 dst-ip
                0.0.0.0/0               192.168.0.1 dst-ip rtoe-GR_cchen414-fzb7j-worker-0-nvmxn
```

The rtoe-GR_cchen414-fzb7j-worker-0-nvmxn is a port on Gateway Router, which points to the br-ex IP address

```txt
router c22f406d-d9e3-4e1d-8666-24529072dcec (GR_cchen414-fzb7j-worker-0-nvmxn)
    port rtoe-GR_cchen414-fzb7j-worker-0-nvmxn
        mac: "fa:16:3e:23:2a:69"
        networks: ["192.168.2.82/16"]
```

Taking a look at br-ex, it not only has the node-ip, but also an IP starts with 169.254. We will cover 169.254 later.

```bash

sh-5.1# ip addr show br-ex
8: br-ex: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 7950 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether fa:16:3e:23:2a:69 brd ff:ff:ff:ff:ff:ff
    inet 192.168.2.82/16 brd 192.168.255.255 scope global dynamic noprefixroute br-ex
       valid_lft 32381sec preferred_lft 32381sec
    inet 169.254.169.2/29 brd 169.254.169.7 scope global br-ex
       valid_lft forever preferred_lft forever

```

The next two routes should be easy to understand. If the target is Pod subnet 10.128.0.0/14, then forward the traffic to 100.64.0.1, in case you forget what is 100.64.0.1:

```bash

router 9158237b-b350-4e36-9014-3c3e64d09dfe (ovn_cluster_router)
    port rtots-cchen414-fzb7j-worker-0-nvmxn
        mac: "0a:58:64:58:00:05"
        networks: ["100.88.0.5/16"]
    port rtoj-ovn_cluster_router
        mac: "0a:58:64:40:00:01"
        networks: ["100.64.0.1/16"]

```

The last one is the default gateway. The node's default gateway is exactly 192.168.0.1. So for outbound traffic, the packets will be forwarded to rtoe port and sent to external switch.

```bash

sh-5.1# ip route
default via 192.168.0.1 dev br-ex proto dhcp src 192.168.2.82 metric 48

```
