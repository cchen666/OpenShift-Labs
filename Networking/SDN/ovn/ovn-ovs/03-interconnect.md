# Lab 03: Interconnect — Cross-Zone Ping

## Objective

Connect two OVN zones via a transit switch, create a fake VM on VM2 (zone `az2`),
and ping from `vm1` (10.0.1.10, zone az1) to `vm3` (10.0.2.10, zone az2) across zones.

This is the core of OVN Interconnect mode.

## Prerequisites

- [Lab 01](01-lab-setup.md) completed — all daemons running
- [Lab 02](02-logical-switch.md) completed — `ls-az1` with `vm1` and `vm2` exist on VM1

## Theory

In IC mode, cross-zone communication requires:

1. **Logical Routers** in each zone — to route between the local subnet and the transit network
2. **Transit Switch** — a special logical switch managed by `ovn-ic` that spans all zones
3. **ovn-ic** — automatically creates `type: remote` ports for other zones on the transit switch

```text
               Zone az1                    IC                    Zone az2
          ┌─────────────┐            ┌───────────┐         ┌─────────────┐
vm1 ──── ls-az1         │            │           │         │         ls-az2 ──── vm3
          │    ↕ (patch) │            │           │         │ (patch) ↕    │
          │ router-az1   │            │           │         │  router-az2  │
          │ 100.88.0.1   │            │ transit   │         │  100.88.0.2  │
          │    ↕ (patch) │            │ switch    │         │ (patch) ↕    │
          │ ts1 (local)──┼── Geneve ──┼── ts1 ────┼─ Geneve─┼──ts1 (local)│
          └─────────────┘            └───────────┘         └─────────────┘
```

The packet flow for vm1 → vm3:
1. vm1 sends to default gateway (router-az1)
2. router-az1 looks up route for 10.0.2.0/24 → nexthop 100.88.0.2 via transit switch
3. Packet enters transit switch, encapsulated in Geneve, sent to VM2
4. VM2's ovn-controller delivers packet to router-az2
5. router-az2 routes to ls-az2 → delivers to vm3

## Part A: Create Topology on VM2 (Zone az2)

### Step 1: Create Logical Switch and Port on VM2

On **VM2**:

```bash
# Snapshot baseline
ovn-nbctl show > /tmp/nb-before.txt
ovn-sbctl show > /tmp/sb-before.txt
ovs-ofctl dump-flows br-int > /tmp/ovs-flows-before.txt

# Create logical switch for az2
ovn-nbctl ls-add ls-az2

# Create port for vm3
ovn-nbctl lsp-add ls-az2 ls-az2-vm3
ovn-nbctl lsp-set-addresses ls-az2-vm3 "02:ac:10:02:00:10 10.0.2.10"
ovn-nbctl lsp-set-port-security ls-az2-vm3 "02:ac:10:02:00:10 10.0.2.10"

ovn-nbctl show
```

### Step 2: Create Fake VM on VM2

On **VM2**:

```bash
ip netns add vm3
ovs-vsctl add-port br-int vm3 -- set interface vm3 type=internal
ip link set vm3 netns vm3
ip netns exec vm3 ip link set vm3 address 02:ac:10:02:00:10
ip netns exec vm3 ip addr add 10.0.2.10/24 dev vm3
ip netns exec vm3 ip link set vm3 up
ovs-vsctl set Interface vm3 external_ids:iface-id=ls-az2-vm3

ip netns exec vm3 ip addr show vm3
```

### Step 3: Verify on VM2

```bash
ovn-sbctl show
# Should show:
# Chassis "vm2" with Port_Binding "ls-az2-vm3"
```

At this point, vm3 is isolated — no routing, no cross-zone connectivity.

## Part B: Create Logical Routers

### Step 4: Create Router in Zone az1

On **VM1**:

```bash
# Snapshot
ovn-nbctl show > /tmp/nb-before-router.txt
ovn-sbctl lflow-list > /tmp/sb-lflows-before-router.txt

# Create the router
ovn-nbctl lr-add router-az1

# Connect router to ls-az1
# Router port facing the logical switch
ovn-nbctl lrp-add router-az1 router-az1-ls 02:ac:10:01:00:01 10.0.1.1/24

# Switch port connecting back to the router
ovn-nbctl lsp-add ls-az1 ls-az1-router
ovn-nbctl lsp-set-type ls-az1-router router
ovn-nbctl lsp-set-addresses ls-az1-router router
ovn-nbctl lsp-set-options ls-az1-router router-port=router-az1-ls

ovn-nbctl show
```

Expected output:

```text
switch <uuid> (ls-az1)
    port ls-az1-router
        type: router
        addresses: ["router"]
        router-port: router-az1-ls
    port ls-az1-vm1
        addresses: ["02:ac:10:01:00:10 10.0.1.10"]
    port ls-az1-vm2
        addresses: ["02:ac:10:01:00:11 10.0.1.11"]
router <uuid> (router-az1)
    port router-az1-ls
        mac: "02:ac:10:01:00:01"
        networks: ["10.0.1.1/24"]
```

#### Configure default gateway for vm1 and vm2

The fake VMs need a default route pointing to the router.

On **VM1**:

```bash
ip netns exec vm1 ip route add default via 10.0.1.1
ip netns exec vm2 ip route add default via 10.0.1.1

# Verify
ip netns exec vm1 ip route show
# Expected:
# default via 10.0.1.1 dev vm1
# 10.0.1.0/24 dev vm1 proto kernel scope link src 10.0.1.10
```

#### Verify NBDB → SBDB mapping for the router

```bash
# Router creates a new Datapath_Binding
ovn-sbctl find Datapath_Binding external_ids:name=router-az1

# The router-switch connection creates patch port bindings
ovn-sbctl find Port_Binding logical_port=router-az1-ls
ovn-sbctl find Port_Binding logical_port=ls-az1-router

# Check router logical flows
ovn-sbctl lflow-list router-az1
```

Key router logical flows:

```text
# IP routing — connected subnet
table=X (lr_in_ip_routing): ip4.dst == 10.0.1.0/24
                             → set nexthop, outport = "router-az1-ls"

# ARP resolution for nexthop
table=Y (lr_in_arp_resolve): outport == "router-az1-ls" && ...
                              → eth.dst = <resolved MAC>
```

#### Verify OVS — Patch ports

```bash
ovs-vsctl show
```

You should now see **patch ports** connecting the switch and router datapaths:

```text
Bridge br-int
    ...
    Port patch-router-az1-ls-to-ls-az1-router
        Interface patch-router-az1-ls-to-ls-az1-router
            type: patch
            options: {peer=patch-ls-az1-router-to-router-az1-ls}
    Port patch-ls-az1-router-to-router-az1-ls
        Interface patch-ls-az1-router-to-router-az1-ls
            type: patch
            options: {peer=patch-router-az1-ls-to-ls-az1-router}
```

These patch ports are how OVS implements the connection between logical switch
and logical router within a single bridge.

### Step 5: Create Router in Zone az2

On **VM2**:

```bash
# Create the router
ovn-nbctl lr-add router-az2

# Connect router to ls-az2
ovn-nbctl lrp-add router-az2 router-az2-ls 02:ac:10:02:00:01 10.0.2.1/24

ovn-nbctl lsp-add ls-az2 ls-az2-router
ovn-nbctl lsp-set-type ls-az2-router router
ovn-nbctl lsp-set-addresses ls-az2-router router
ovn-nbctl lsp-set-options ls-az2-router router-port=router-az2-ls

ovn-nbctl show

# Set default gateway for vm3
ip netns exec vm3 ip route add default via 10.0.2.1

# Verify
ovn-sbctl show
ovs-vsctl show
```

At this point, each zone has its own router, but they can't reach each other.

```bash
# This should FAIL — no cross-zone route exists
ip netns exec vm1 ping -c 2 -W 1 10.0.2.10
# Expected: 100% packet loss
```

## Part C: Set Up the Transit Switch (Interconnect)

This is where IC mode comes to life.

### Step 6: Create the Transit Switch

On **VM1** (where IC databases are hosted):

```bash
# Snapshot IC state
ovn-ic-nbctl --db=unix:/run/ovn/ovn_ic_nb_db.sock ts-list
ovn-ic-sbctl --db=unix:/run/ovn/ovn_ic_sb_db.sock list Route

# Create the transit switch in IC-NB database
ovn-ic-nbctl --db=unix:/run/ovn/ovn_ic_nb_db.sock ts-add ts1

# Verify
ovn-ic-nbctl --db=unix:/run/ovn/ovn_ic_nb_db.sock ts-list
```

Expected output:

```text
ts1
```

#### What happened automatically?

The `ovn-ic` daemon on each zone detected the new transit switch in IC-NB
and created a **local logical switch** named `ts1` in each zone's NBDB.

On **both VMs**, check:

```bash
ovn-nbctl show
# You should now see an additional switch:
# switch <uuid> (ts1)
#     (no ports yet)

ovn-nbctl find Logical_Switch name=ts1
# Check other_config — it should have interconn-ts set
```

### Step 7: Connect Routers to the Transit Switch

#### On VM1 (zone az1):

```bash
# Snapshot
ovn-sbctl lflow-list > /tmp/sb-lflows-before-ts.txt

# Add router port facing the transit switch
ovn-nbctl lrp-add router-az1 router-az1-ts 02:ac:10:88:00:01 100.88.0.1/16

# Connect transit switch to the router
ovn-nbctl lsp-add ts1 ts1-router-az1
ovn-nbctl lsp-set-type ts1-router-az1 router
ovn-nbctl lsp-set-addresses ts1-router-az1 router
ovn-nbctl lsp-set-options ts1-router-az1 router-port=router-az1-ts

# Add a static route for az2's subnet
ovn-nbctl lr-route-add router-az1 10.0.2.0/24 100.88.0.2

ovn-nbctl show
ovn-nbctl lr-route-list router-az1
```

Expected routing table:

```text
IPv4 Routes
Route Table <main>:
          10.0.2.0/24          100.88.0.2 dst-ip
```

> **Note:** In a real OpenShift cluster, `ovn-ic` creates these routes automatically
> by exchanging route advertisements via IC-SB. In this manual lab, we add them
> explicitly. You can also enable automatic route learning — see the note at the end.

#### On VM2 (zone az2):

```bash
# Add router port facing the transit switch
ovn-nbctl lrp-add router-az2 router-az2-ts 02:ac:10:88:00:02 100.88.0.2/16

# Connect transit switch to the router
ovn-nbctl lsp-add ts1 ts1-router-az2
ovn-nbctl lsp-set-type ts1-router-az2 router
ovn-nbctl lsp-set-addresses ts1-router-az2 router
ovn-nbctl lsp-set-options ts1-router-az2 router-port=router-az2-ts

# Add a static route for az1's subnet
ovn-nbctl lr-route-add router-az2 10.0.1.0/24 100.88.0.1

ovn-nbctl show
ovn-nbctl lr-route-list router-az2
```

### Step 8: Verify IC State

#### Check IC-SB for registered gateways and routes

On **VM1**:

```bash
# List gateways (each zone's router port on the transit switch)
ovn-ic-sbctl --db=unix:/run/ovn/ovn_ic_sb_db.sock list Gateway

# List route advertisements
ovn-ic-sbctl --db=unix:/run/ovn/ovn_ic_sb_db.sock list Route
```

#### Check transit switch ports

On **VM1**:

```bash
ovn-nbctl show | grep -A5 "ts1"
```

Expected: You should see the router port `ts1-router-az1` (type: router, local)
and possibly a `type: remote` port for az2.

On **VM2**:

```bash
ovn-nbctl show | grep -A5 "ts1"
```

Expected: You should see `ts1-router-az2` (local) and a `type: remote` port for az1.

The **`type: remote`** ports are created automatically by `ovn-ic`. They represent
ports in other zones that are connected to the same transit switch.

#### Check SBDB — Transit datapath and tunnel

On **both VMs**:

```bash
ovn-sbctl show
```

You should now see the Geneve tunnel between the two chassis:

```text
Chassis "vm1"
    hostname: "ovn-central"
    Encap geneve
        ip: "192.168.122.101"
        options: {csum="true"}
    Port_Binding "ls-az1-vm1"
    Port_Binding "ls-az1-vm2"
    Port_Binding "ts1-router-az1"
```

#### Check OVS — Geneve tunnel port

```bash
ovs-vsctl show
```

You should see a Geneve tunnel port on br-int:

```text
Port ovn-vm2-0
    Interface ovn-vm2-0
        type: geneve
        options: {csum="true", key=flow, remote_ip="192.168.122.102"}
```

This tunnel is how packets get from one zone to another at the physical level.

### Step 9: Verify Logical Flows for Cross-Zone Routing

On **VM1**:

```bash
# Router flows — should now include route for 10.0.2.0/24
ovn-sbctl lflow-list router-az1 | grep "10.0.2"
```

Expected:

```text
# Routing decision: packets to 10.0.2.0/24 → nexthop 100.88.0.2
table=X (lr_in_ip_routing): ... ip4.dst == 10.0.2.0/24 ...
                              → ip.ttl--; reg0 = 100.88.0.2; ... outport = "router-az1-ts"; next;
```

```bash
# Check OpenFlow rules that implement this routing
ovs-ofctl dump-flows br-int | grep "100.88"
```

## Part D: Test Cross-Zone Connectivity

### Step 10: Ping Across Zones!

On **VM1**:

```bash
ip netns exec vm1 ping -c 3 10.0.2.10
```

Expected:

```text
PING 10.0.2.10 (10.0.2.10) 56(84) bytes of data.
64 bytes from 10.0.2.10: icmp_seq=1 ttl=62 time=X.XX ms
64 bytes from 10.0.2.10: icmp_seq=2 ttl=62 time=X.XX ms
64 bytes from 10.0.2.10: icmp_seq=3 ttl=62 time=X.XX ms
```

> **Note the TTL of 62** (not 64): the packet traversed 2 logical routers
> (router-az1 → router-az2), each decrementing TTL by 1.

### Step 11: Trace the Complete Packet Path

#### OVN logical trace (on VM1)

```bash
ovn-trace router-az1 \
    'inport == "router-az1-ls" && eth.src == 02:ac:10:01:00:10 && eth.dst == 02:ac:10:01:00:01 && ip4.src == 10.0.1.10 && ip4.dst == 10.0.2.10 && ip.ttl == 64 && icmp4'
```

This traces through:
1. `router-az1`: ingress → route lookup → nexthop 100.88.0.2 → output to transit
2. The trace may stop at the zone boundary (remote port)

#### OVS OpenFlow trace (on VM1)

```bash
OFPORT=$(ovs-vsctl get Interface vm1 ofport)
ovs-appctl ofproto/trace br-int \
    "in_port=$OFPORT,dl_src=02:ac:10:01:00:10,dl_dst=02:ac:10:01:00:01,dl_type=0x0800,nw_src=10.0.1.10,nw_dst=10.0.2.10,nw_proto=1,nw_ttl=64"
```

This shows the complete OpenFlow pipeline on VM1, ending with output to the Geneve tunnel port.

#### Verify Geneve tunnel traffic

On **VM1 or VM2**, capture the tunnel traffic:

```bash
# On VM2, capture Geneve packets (UDP port 6081)
tcpdump -i eth0 -nn udp port 6081 -c 5
```

While running the ping from vm1, you should see encapsulated Geneve packets between
192.168.122.101 and 192.168.122.102.

## Summary: The Complete IC Mapping

```text
                    NBDB                          SBDB                          OVS
Zone az1 (VM1):
  ls-az1            Logical_Switch            →  Datapath_Binding           →  metadata=0xN in flows
  ls-az1-vm1        Logical_Switch_Port       →  Port_Binding(chassis=vm1)  →  OVS port vm1 on br-int
  router-az1        Logical_Router            →  Datapath_Binding           →  metadata=0xM in flows
  router-az1-ls     Logical_Router_Port       →  Port_Binding(type:patch)   →  patch port pair
  router-az1-ts     Logical_Router_Port       →  Port_Binding(type:patch)   →  patch port pair
  ls-az1-router     LSP(type:router)          →  Port_Binding(type:patch)   →  patch port pair
  ts1               Logical_Switch(transit)   →  Datapath_Binding           →  metadata=0xK in flows
  ts1-router-az1    LSP(type:router)          →  Port_Binding(type:patch)   →  patch port pair
  (remote az2 port) LSP(type:remote)          →  Port_Binding(type:remote)  →  Geneve tunnel output

IC Databases:
  ts1               Transit_Switch (IC-NB)
  az1, az2          Availability_Zone (IC-SB)
  10.0.1.0/24       Route (IC-SB, from az1)
  10.0.2.0/24       Route (IC-SB, from az2)
```

## Map to OpenShift IC Mode

| This Lab | OpenShift Equivalent |
|----------|---------------------|
| `az1`, `az2` | Each node is a zone (zone name = node name) |
| `router-az1` | `ovn_cluster_router` (per-zone instance) |
| `router-az1-ls` | Router port to node logical switch |
| `router-az1-ts` | Router port `rtots-<node>` (100.88.0.X) |
| `ts1` | `transit_switch` (100.88.0.0/16) |
| `type: remote` ports | Remote node ports on transit switch |
| `10.0.1.0/24` route | Pod subnet route exchanged via IC |
| Static routes | Automatically managed by `ovn-ic` in OpenShift |
| Geneve tunnel | Node-to-node tunnel for cross-node pod traffic |

Compare with your existing notes in `ovn-arch/ovn-router.md`:
- `100.64.0.0/16` = join switch (Gateway Router ↔ cluster_router) — not in this lab
- `100.88.0.0/16` = transit switch — **this is what we just built**
- `rtots-<node>` = our `router-az1-ts` / `router-az2-ts`

## Automatic Route Learning (Optional)

In this lab we added static routes manually (`lr-route-add`). In OpenShift,
`ovn-ic` handles this automatically. To enable automatic route learning:

```bash
# On both VMs, set the "learn routes" option on the router port
# connected to the transit switch
ovn-nbctl set Logical_Router_Port router-az1-ts options:interconn-ts=ts1
ovn-nbctl set Logical_Router_Port router-az2-ts options:interconn-ts=ts1
```

With this set, `ovn-ic`:
1. Advertises each zone's connected subnets to IC-SB
2. Imports remote zone subnets as routes in the local router
3. You can remove the manual static routes and they'll be re-learned

## Cleanup

```bash
# === On VM1 ===
ip netns del vm1
ip netns del vm2
ovs-vsctl --if-exists --with-iface del-port br-int vm1
ovs-vsctl --if-exists --with-iface del-port br-int vm2
ovn-nbctl ls-del ls-az1
ovn-nbctl lr-del router-az1
# Transit switch ports are cleaned up when ovn-ic detects the router is gone

# === On VM2 ===
ip netns del vm3
ovs-vsctl --if-exists --with-iface del-port br-int vm3
ovn-nbctl ls-del ls-az2
ovn-nbctl lr-del router-az2

# === On VM1 (IC cleanup) ===
ovn-ic-nbctl --db=unix:/run/ovn/ovn_ic_nb_db.sock ts-del ts1
```

## Troubleshooting

```bash
# If ping fails, check step by step:

# 1. Is the port bound?
ovn-sbctl find Port_Binding logical_port=ls-az2-vm3 | grep chassis

# 2. Are routes present?
ovn-nbctl lr-route-list router-az1

# 3. Are transit switch remote ports created?
ovn-nbctl show | grep -A3 "ts1"

# 4. Is the Geneve tunnel established?
ovs-vsctl show | grep geneve

# 5. Check ovn-ic logs for errors
tail -50 /var/log/ovn/ovn-ic.log

# 6. Check ovn-controller logs
tail -50 /var/log/ovn/ovn-controller.log

# 7. Verify firewall allows Geneve (UDP 6081)
# On both VMs:
firewall-cmd --list-ports | grep 6081
# If missing:
firewall-cmd --add-port=6081/udp
```
