# OVN Interconnect Mode — Hands-On Tutorial

This tutorial walks through building an OVN Interconnect (IC) cluster from scratch
on real VMs, following the step-by-step style of
[A Primer on OVN](https://github.com/dspinhirne/ovn-tutorial/blob/main/20160919-A-Primer-On-OVN.md).

The goal: create NBDB entities one by one, verify the corresponding SBDB logical flows
and OVS OpenFlow rules at each step, and ultimately ping between two network namespaces
on two different VMs connected via OVN Interconnect.

## Why IC Mode?

Since OpenShift 4.14, OVN-Kubernetes uses **Interconnect mode** where each node is its
own OVN zone with independent NB/SB databases. This replaces the older single-zone
architecture where all nodes shared one central NB/SB.

Benefits:
- **Scalability** — each node's northd only processes its own zone's logical flows
- **Fault isolation** — a node's NB/SB failure doesn't affect other nodes
- **Reduced DB size** — each zone only stores local topology

## Architecture

```text
                     IC-NB Database
                     IC-SB Database
                          |
              +-----------+-----------+
              |                       |
         [ovn-ic]                [ovn-ic]
              |                       |
    Zone: az1 (VM1)         Zone: az2 (VM2)
   +------------------+   +------------------+
   |  NB DB  |  SB DB |   |  NB DB  |  SB DB |
   |     northd       |   |     northd       |
   |  ovn-controller   |   |  ovn-controller   |
   |  ovs-vswitchd     |   |  ovs-vswitchd     |
   +------------------+   +------------------+
```

## Lab Topology (End State)

```text
Zone az1 (VM1)                                  Zone az2 (VM2)

  ns:vm1 (10.0.1.10/24)                          ns:vm3 (10.0.2.10/24)
  ns:vm2 (10.0.1.11/24)                                |
        \     /                                         |
    [ls-az1] logical switch                       [ls-az2] logical switch
         |                                              |
    [router-az1]                                  [router-az2]
    10.0.1.1/24                                   10.0.2.1/24
    100.88.0.1/16                                 100.88.0.2/16
         |                                              |
         +------------ [transit_switch] ----------------+
                        100.88.0.0/16
                     (managed by ovn-ic)
```

## Lab Environment

- **OS:** RHEL 9 (x86_64)
- **Packages:** `openvswitch3.3`, `ovn24.03-central`, `ovn24.03-host` (versions may vary)
- **Two VMs** connected on a shared network

## Addressing Plan

| Component          | Address / MAC              | Zone |
|--------------------|----------------------------|------|
| VM1 management IP  | 192.168.122.101            | az1  |
| VM2 management IP  | 192.168.122.102            | az2  |
| ls-az1 subnet      | 10.0.1.0/24                | az1  |
| ls-az2 subnet      | 10.0.2.0/24                | az2  |
| router-az1 → ls    | 10.0.1.1 / 02:ac:10:01:00:01 | az1  |
| router-az1 → ts    | 100.88.0.1 / 02:ac:10:88:00:01 | az1  |
| router-az2 → ls    | 10.0.2.1 / 02:ac:10:02:00:01 | az2  |
| router-az2 → ts    | 100.88.0.2 / 02:ac:10:88:00:02 | az2  |
| vm1 (namespace)    | 10.0.1.10 / 02:ac:10:01:00:10 | az1  |
| vm2 (namespace)    | 10.0.1.11 / 02:ac:10:01:00:11 | az1  |
| vm3 (namespace)    | 10.0.2.10 / 02:ac:10:02:00:10 | az2  |
| transit_switch     | 100.88.0.0/16              | IC   |

## Labs

| Lab | File | Topic |
|-----|------|-------|
| 01  | [01-lab-setup.md](01-lab-setup.md) | Install OVS/OVN, start all daemons, verify |
| 02  | [02-logical-switch.md](02-logical-switch.md) | Single zone L2: create logical switch, verify NBDB→SBDB→OVS |
| 03  | [03-interconnect.md](03-interconnect.md) | IC mode: routers, transit switch, cross-zone ping |

## Tools Cheat Sheet

```bash
# NBDB
ovn-nbctl show                          # overview of all logical entities
ovn-nbctl list <Table>                  # list all rows in a table
ovn-nbctl find <Table> <col>=<val>      # find specific rows
ovn-nbctl lr-route-list <router>        # show routing table

# SBDB
ovn-sbctl show                          # chassis and port bindings
ovn-sbctl lflow-list [datapath]         # logical flows
ovn-sbctl list Port_Binding             # port binding details
ovn-sbctl list Datapath_Binding         # datapath info

# IC
ovn-ic-nbctl ts-list                    # list transit switches
ovn-ic-sbctl list Availability_Zone     # list zones
ovn-ic-sbctl list Gateway               # list gateways
ovn-ic-sbctl list Route                 # list advertised routes

# OVS
ovs-vsctl show                          # bridge/port overview
ovs-ofctl dump-flows br-int [table=N]   # OpenFlow rules
ovs-appctl ofproto/trace br-int <pkt>   # trace packet through flows

# Snapshot helper
./scripts/snapshot.sh before            # capture state before change
./scripts/snapshot.sh after             # capture state + show diff
```
