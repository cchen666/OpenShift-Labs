# Lab 02: Logical Switch — Single Zone L2

## Objective

Create a logical switch with two ports in zone `az1` (VM1), connect two fake VMs
(network namespaces), and verify the **NBDB → SBDB → OVS** mapping at each step.

This lab works entirely within a single zone — no IC involved yet.

## Prerequisites

- [Lab 01](01-lab-setup.md) completed — all daemons running on both VMs

## Theory

A **Logical Switch** is OVN's L2 broadcast domain (like a VLAN or a virtual switch).
When you create one:

```text
NBDB:  Logical_Switch row created
         ↓ northd
SBDB:  Datapath_Binding row created (assigns a tunnel key)
       Logical_Flow rows created (L2 forwarding pipeline)
         ↓ ovn-controller
OVS:   OpenFlow rules in br-int tables (port security, ACL, L2 lookup, output)
```

## Step 1: Capture Baseline State

Before making any changes, snapshot the current state.

### On VM1

```bash
# Save baseline
ovn-nbctl show > /tmp/nb-before.txt
ovn-sbctl show > /tmp/sb-before.txt
ovn-sbctl lflow-list > /tmp/sb-lflows-before.txt
ovs-ofctl dump-flows br-int > /tmp/ovs-flows-before.txt
```

## Step 2: Create the Logical Switch

### On VM1

```bash
ovn-nbctl ls-add ls-az1
ovn-nbctl show
```

Expected output:

```text
switch <uuid> (ls-az1)
```

### Verify SBDB — Datapath Binding

```bash
ovn-sbctl list Datapath_Binding
```

You should see a new datapath for `ls-az1` with a `tunnel_key` assigned.
This tunnel key is how OVN identifies this logical switch in Geneve headers.

```bash
# Easier way to see it
ovn-sbctl find Datapath_Binding external_ids:name=ls-az1
```

### Verify OVS — No OpenFlow changes yet

```bash
ovs-ofctl dump-flows br-int > /tmp/ovs-flows-after-ls.txt
diff /tmp/ovs-flows-before.txt /tmp/ovs-flows-after-ls.txt
```

You should see **no changes** (or very minimal). A logical switch without ports
doesn't produce meaningful OpenFlow rules — the real flows come when ports are bound.

## Step 3: Create Logical Switch Ports

```bash
# Port for vm1
ovn-nbctl lsp-add ls-az1 ls-az1-vm1
ovn-nbctl lsp-set-addresses ls-az1-vm1 "02:ac:10:01:00:10 10.0.1.10"
ovn-nbctl lsp-set-port-security ls-az1-vm1 "02:ac:10:01:00:10 10.0.1.10"

# Port for vm2
ovn-nbctl lsp-add ls-az1 ls-az1-vm2
ovn-nbctl lsp-set-addresses ls-az1-vm2 "02:ac:10:01:00:11 10.0.1.11"
ovn-nbctl lsp-set-port-security ls-az1-vm2 "02:ac:10:01:00:11 10.0.1.11"

ovn-nbctl show
```

Expected output:

```text
switch <uuid> (ls-az1)
    port ls-az1-vm1
        addresses: ["02:ac:10:01:00:10 10.0.1.10"]
    port ls-az1-vm2
        addresses: ["02:ac:10:01:00:11 10.0.1.11"]
```

**What each command does:**
- `lsp-add` → creates a Logical_Switch_Port in NBDB (just metadata, not bound yet)
- `lsp-set-addresses` → tells OVN what MAC+IP this port will use (enables ARP responder)
- `lsp-set-port-security` → restricts the port to only allow this MAC+IP (anti-spoofing)

### Verify SBDB — Port Bindings (not yet bound)

```bash
ovn-sbctl list Port_Binding
```

You'll see entries for `ls-az1-vm1` and `ls-az1-vm2`, but `chassis` will be empty —
no physical host has claimed these ports yet.

```bash
# Check the chassis field specifically
ovn-sbctl find Port_Binding logical_port=ls-az1-vm1
# chassis should be: []
```

### Verify SBDB — Logical Flows

```bash
ovn-sbctl lflow-list ls-az1
```

This shows the logical flow pipeline that northd generated. Key tables to notice:

```text
# Ingress pipeline (packets entering the switch)
table=0  (ls_in_check_port_sec)   — validates source MAC
table=1  (ls_in_apply_port_sec)   — applies port security
table=7  (ls_in_pre_acl)          — marks packets for ACL processing
table=8  (ls_in_pre_lb)           — marks packets for load balancer
table=17 (ls_in_arp_rsp)          — responds to ARP requests locally
table=27 (ls_in_l2_lkup)          — L2 destination MAC lookup → sets outport

# Egress pipeline (packets leaving the switch)
table=0  (ls_out_pre_acl)
table=8  (ls_out_apply_port_sec)  — validates destination MAC
table=9  (ls_out_check_port_sec)
```

> **Note:** Table numbers may vary between OVN versions. The table names are stable.

### Verify OVS — Still no significant changes

The ports exist in SBDB but aren't bound to a chassis yet, so ovn-controller
hasn't programmed OVS flows for them.

## Step 4: Create Fake VMs (Network Namespaces)

This is where the logical ports get "brought to life" by connecting them to
actual OVS ports.

### On VM1

```bash
# Create namespace "vm1" and wire it to br-int
ip netns add vm1
ovs-vsctl add-port br-int vm1 -- set interface vm1 type=internal
ip link set vm1 netns vm1
ip netns exec vm1 ip link set vm1 address 02:ac:10:01:00:10
ip netns exec vm1 ip addr add 10.0.1.10/24 dev vm1
ip netns exec vm1 ip link set vm1 up

# THIS IS THE KEY LINE — it binds the OVS port to the OVN logical port
ovs-vsctl set Interface vm1 external_ids:iface-id=ls-az1-vm1

# Create namespace "vm2"
ip netns add vm2
ovs-vsctl add-port br-int vm2 -- set interface vm2 type=internal
ip link set vm2 netns vm2
ip netns exec vm2 ip link set vm2 address 02:ac:10:01:00:11
ip netns exec vm2 ip addr add 10.0.1.11/24 dev vm2
ip netns exec vm2 ip link set vm2 up
ovs-vsctl set Interface vm2 external_ids:iface-id=ls-az1-vm2

# Verify namespaces
ip netns exec vm1 ip addr show vm1
ip netns exec vm2 ip addr show vm2
```

**Critical line explained:**
```bash
ovs-vsctl set Interface vm1 external_ids:iface-id=ls-az1-vm1
```
This tells OVS: "this physical port corresponds to OVN logical port `ls-az1-vm1`."
ovn-controller detects this mapping, binds the port in SBDB, and programs OpenFlow rules.

## Step 5: Verify the Full NBDB → SBDB → OVS Mapping

### 5a: NBDB — No changes (we already set this up)

```bash
ovn-nbctl show
```

### 5b: SBDB — Ports are now bound to chassis "vm1"

```bash
ovn-sbctl show
```

Expected:

```text
Chassis "vm1"
    hostname: "ovn-central"
    Encap geneve
        ip: "192.168.122.101"
        options: {csum="true"}
    Port_Binding "ls-az1-vm1"
    Port_Binding "ls-az1-vm2"
```

Both ports are now bound to the `vm1` chassis!

```bash
# Detailed port binding — note the tunnel_key and datapath
ovn-sbctl find Port_Binding logical_port=ls-az1-vm1
```

### 5c: SBDB — Logical Flows now reference our ports

```bash
# Filter for flows mentioning our ports
ovn-sbctl lflow-list ls-az1 | grep -E "ls-az1-vm1|ls-az1-vm2"
```

Key flows to observe:

```text
# Port security — only allow our MAC as source
table=0 (ls_in_check_port_sec): inport == "ls-az1-vm1" && eth.src == {02:ac:10:01:00:10}
                                 → next;

# ARP responder — OVN answers ARP on behalf of known ports
table=17 (ls_in_arp_rsp): arp.tpa == 10.0.1.10 && arp.op == 1
                           → reply with 02:ac:10:01:00:10

# L2 lookup — destination MAC → set outport
table=27 (ls_in_l2_lkup): eth.dst == 02:ac:10:01:00:10
                           → outport = "ls-az1-vm1"; output;

# Egress port security — validate destination
table=8 (ls_out_apply_port_sec): outport == "ls-az1-vm1" && eth.dst == 02:ac:10:01:00:10
                                  → output;
```

### 5d: OVS — OpenFlow rules on br-int

```bash
ovs-ofctl dump-flows br-int
```

Now you'll see real OpenFlow rules. Compare with the baseline:

```bash
ovs-ofctl dump-flows br-int > /tmp/ovs-flows-after-bind.txt
diff /tmp/ovs-flows-before.txt /tmp/ovs-flows-after-bind.txt
```

Key OpenFlow entries to look for:

```bash
# Show flows with context — table 0 is the ingress classifier
ovs-ofctl dump-flows br-int table=0

# Find flows that reference our port numbers
# First, find the OVS ofport numbers
ovs-vsctl get Interface vm1 ofport
ovs-vsctl get Interface vm2 ofport
```

The OpenFlow rules encode the SBDB logical flows into hardware-level match/action pairs.
Each SBDB logical flow table maps to one or more OpenFlow tables.

### 5e: OVS Bridge State

```bash
ovs-vsctl show
```

You should now see `vm1` and `vm2` ports on `br-int`:

```text
Bridge br-int
    fail_mode: secure
    Port vm1
        Interface vm1
            type: internal
    Port vm2
        Interface vm2
            type: internal
    Port br-int
        Interface br-int
            type: internal
```

## Step 6: Test Connectivity

### Ping from vm1 to vm2 (same host, same switch)

```bash
ip netns exec vm1 ping -c 3 10.0.1.11
```

Expected:

```text
PING 10.0.1.11 (10.0.1.11) 56(84) bytes of data.
64 bytes from 10.0.1.11: icmp_seq=1 ttl=64 time=0.xxx ms
64 bytes from 10.0.1.11: icmp_seq=2 ttl=64 time=0.xxx ms
64 bytes from 10.0.1.11: icmp_seq=3 ttl=64 time=0.xxx ms
```

### Verify ARP resolution

```bash
ip netns exec vm1 ip neigh show
# Should show: 10.0.1.11 dev vm1 lladdr 02:ac:10:01:00:11 REACHABLE
```

### Trace packet path through logical flows

```bash
ovn-trace ls-az1 \
    'inport == "ls-az1-vm1" && eth.src == 02:ac:10:01:00:10 && eth.dst == 02:ac:10:01:00:11 && ip4.src == 10.0.1.10 && ip4.dst == 10.0.1.11 && ip.ttl == 64 && icmp4'
```

This shows the exact logical flow pipeline the packet traverses — compare it with
the `lflow-list` output from Step 5c.

### Trace at OVS level (OpenFlow)

```bash
# Get the ofport for vm1
OFPORT=$(ovs-vsctl get Interface vm1 ofport)

ovs-appctl ofproto/trace br-int \
    "in_port=$OFPORT,dl_src=02:ac:10:01:00:10,dl_dst=02:ac:10:01:00:11,dl_type=0x0800,nw_src=10.0.1.10,nw_dst=10.0.1.11,nw_proto=1"
```

This shows which OpenFlow table rules the packet matches — the physical implementation
of the logical pipeline.

## Summary: The Complete Mapping

```text
NBDB                          SBDB                           OVS (br-int)
─────────────────────────────────────────────────────────────────────────────
Logical_Switch "ls-az1"  →  Datapath_Binding (tunnel_key=N)  →  Flow rules use
                                                                 metadata=0xN

Logical_Switch_Port      →  Port_Binding                     →  OVS port on br-int
  "ls-az1-vm1"               chassis="vm1"                      external_ids:
  addr: 02:ac:10:01:00:10    tunnel_key=M                       iface-id=ls-az1-vm1

lsp-set-addresses        →  Logical_Flow (ls_in_arp_rsp)     →  ARP responder
  "02:ac:10:01:00:10          match: arp.tpa == 10.0.1.10       OpenFlow rules
   10.0.1.10"                 action: reply                     (table 17→OF table)

lsp-set-port-security    →  Logical_Flow (ls_in_check_port_sec) →  Port security
  "02:ac:10:01:00:10          match: inport && eth.src             OpenFlow rules
   10.0.1.10"                 action: next or drop                 (table 0→OF table)

(implicit L2 forwarding) →  Logical_Flow (ls_in_l2_lkup)     →  L2 lookup
                              match: eth.dst                      OpenFlow rules
                              action: outport = X; output;        (table 27→OF table)
```

## Map to OpenShift

In OVN-Kubernetes (IC mode), the mapping is:

| This Lab | OpenShift Equivalent |
|----------|---------------------|
| `ls-az1` | Node logical switch (named after the node hostname) |
| `ls-az1-vm1` | Pod logical port (named `<namespace>_<pod>`) |
| `lsp-set-addresses` | Set by ovnkube when pod gets an IP from IPAM |
| `lsp-set-port-security` | Anti-spoofing — pod can only use its assigned MAC+IP |
| `external_ids:iface-id` | Set by ovnkube when CNI creates the pod veth pair |

## Cleanup

**Do NOT clean up** — we'll build on this in [Lab 03](03-interconnect.md).

If you need to clean up for any reason:

```bash
# Remove namespaces
ip netns del vm1
ip netns del vm2

# Remove OVS ports
ovs-vsctl --if-exists --with-iface del-port br-int vm1
ovs-vsctl --if-exists --with-iface del-port br-int vm2

# Remove logical entities
ovn-nbctl ls-del ls-az1
```

---

**Next:** [Lab 03 — Interconnect: Cross-Zone Ping](03-interconnect.md)
