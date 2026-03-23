# Lab 01: Environment Setup

## Objective

Install OVS and OVN on two VMs, start all daemons (including IC components), and
verify that both zones are operational and connected via the IC databases.

## Prerequisites

- Two Linux VMs with network connectivity between them
  - **VM1** (`ovn-central`): 192.168.122.101 — hosts zone `az1` + IC databases
  - **VM2** (`ovn-worker`): 192.168.122.102 — hosts zone `az2`
- Root access on both VMs
- RHEL 9 subscription (or CentOS Stream 9)
- Adjust IPs throughout this guide to match your environment

## Step 1: Install Packages

### On both VMs

OVN/OVS packages on RHEL 9 are versioned. Check available versions first:

```bash
dnf search openvswitch
dnf search ovn
```

Typical package names (version numbers may differ — use the latest available):

```bash
# Install OVS
dnf install -y openvswitch3.3

# Install OVN
dnf install -y ovn24.03 ovn24.03-central ovn24.03-host
```

> **Note:** If the versioned packages are not available, enable the
> `fast-datapath` repository:
> ```bash
> subscription-manager repos --enable fast-datapath-for-rhel-9-x86_64-rpms
> ```
> On CentOS Stream 9, the packages may be named without version suffixes:
> `openvswitch`, `ovn-central`, `ovn-host`.

Verify installation:

```bash
ovs-vsctl --version
ovn-nbctl --version
```

### Configure firewall

OVN requires several ports for inter-VM communication. Open them now to avoid
issues later:

```bash
# On both VMs — Geneve tunnel traffic
firewall-cmd --permanent --add-port=6081/udp

# On VM1 only — IC database access from VM2
firewall-cmd --permanent --add-port=6645/tcp
firewall-cmd --permanent --add-port=6646/tcp

# Optional: NB/SB database access (if you need remote access)
firewall-cmd --permanent --add-port=6641/tcp
firewall-cmd --permanent --add-port=6642/tcp

firewall-cmd --reload
```

## Step 2: Start Open vSwitch

### On both VMs

```bash
# RHEL 9 service name matches the versioned package (e.g., openvswitch3.3)
# Check the actual service name:
systemctl list-unit-files | grep openvswitch

# Start it (adjust name if needed)
systemctl enable --now openvswitch
systemctl status openvswitch
```

> **SELinux note:** If you run into permission errors later when starting OVN
> daemons or creating DB files, set SELinux to permissive for the lab:
> ```bash
> setenforce 0
> # To make it persistent across reboots (lab only — not for production):
> sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
> ```

Verify OVS is running:

```bash
ovs-vsctl show
```

You should see an empty bridge configuration (just the OVS system UUID).

## Step 3: Create the Integration Bridge

OVN manages a single bridge called `br-int`. All logical ports are connected to this bridge.

### On both VMs

```bash
ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure
ovs-vsctl list-br
```

The `fail-mode=secure` ensures the bridge drops all traffic by default until
ovn-controller programs the OpenFlow rules.

## Step 4: Start Zone Databases (NB + SB)

Each zone needs its own Northbound and Southbound databases. We start them manually
to understand what each process does.

### On VM1 (zone az1)

```bash
# Create database files from OVN schemas
# (paths may vary — check /usr/share/ovn/ for schema files)
ovsdb-tool create /etc/ovn/ovnnb_db.db /usr/share/ovn/ovn-nb.ovsschema
ovsdb-tool create /etc/ovn/ovnsb_db.db /usr/share/ovn/ovn-sb.ovsschema

# Start Northbound database server
# Listens on Unix socket (local) and TCP 6641 (for remote access if needed)
ovsdb-server /etc/ovn/ovnnb_db.db \
    --remote=punix:/run/ovn/ovnnb_db.sock \
    --remote=ptcp:6641:0.0.0.0 \
    --pidfile=/run/ovn/ovnnb_db.pid \
    --log-file=/var/log/ovn/ovnnb_db.log \
    --detach

# Start Southbound database server
# Listens on Unix socket (local) and TCP 6642 (for remote access if needed)
ovsdb-server /etc/ovn/ovnsb_db.db \
    --remote=punix:/run/ovn/ovnsb_db.sock \
    --remote=ptcp:6642:0.0.0.0 \
    --pidfile=/run/ovn/ovnsb_db.pid \
    --log-file=/var/log/ovn/ovnsb_db.log \
    --detach
```

### On VM2 (zone az2)

```bash
ovsdb-tool create /etc/ovn/ovnnb_db.db /usr/share/ovn/ovn-nb.ovsschema
ovsdb-tool create /etc/ovn/ovnsb_db.db /usr/share/ovn/ovn-sb.ovsschema

ovsdb-server /etc/ovn/ovnnb_db.db \
    --remote=punix:/run/ovn/ovnnb_db.sock \
    --remote=ptcp:6641:0.0.0.0 \
    --pidfile=/run/ovn/ovnnb_db.pid \
    --log-file=/var/log/ovn/ovnnb_db.log \
    --detach

ovsdb-server /etc/ovn/ovnsb_db.db \
    --remote=punix:/run/ovn/ovnsb_db.sock \
    --remote=ptcp:6642:0.0.0.0 \
    --pidfile=/run/ovn/ovnsb_db.pid \
    --log-file=/var/log/ovn/ovnsb_db.log \
    --detach
```

### Verify databases are running on both VMs

```bash
ovn-nbctl show    # should return empty (no logical entities yet)
ovn-sbctl show    # should return empty (no chassis yet)
```

## Step 5: Start northd

`ovn-northd` is the translator: it reads NBDB (high-level intent) and writes
SBDB (detailed logical flows). Each zone has its own northd.

### On both VMs

```bash
ovn-northd \
    --ovnnb-db=unix:/run/ovn/ovnnb_db.sock \
    --ovnsb-db=unix:/run/ovn/ovnsb_db.sock \
    --pidfile=/run/ovn/ovn-northd.pid \
    --log-file=/var/log/ovn/ovn-northd.log \
    --detach
```

## Step 6: Set Availability Zone Names

This is the key IC configuration — each zone must have a unique name.

### On VM1

```bash
ovn-nbctl set NB_Global . name=az1
ovn-nbctl get NB_Global . name
# Expected output: "az1"
```

### On VM2

```bash
ovn-nbctl set NB_Global . name=az2
ovn-nbctl get NB_Global . name
# Expected output: "az2"
```

## Step 7: Configure and Start ovn-controller

`ovn-controller` runs on each host, reads SBDB logical flows, and programs
OVS OpenFlow rules on `br-int`. It also registers the host as a "chassis".

### On VM1

```bash
ovs-vsctl set open . external-ids:ovn-bridge=br-int
ovs-vsctl set open . external-ids:ovn-remote=unix:/run/ovn/ovnsb_db.sock
ovs-vsctl set open . external-ids:ovn-encap-type=geneve
ovs-vsctl set open . external-ids:ovn-encap-ip=192.168.122.101
ovs-vsctl set open . external-ids:system-id=vm1

ovn-controller unix:/run/ovn/ovnsb_db.sock \
    --pidfile=/run/ovn/ovn-controller.pid \
    --log-file=/var/log/ovn/ovn-controller.log \
    --detach
```

### On VM2

```bash
ovs-vsctl set open . external-ids:ovn-bridge=br-int
ovs-vsctl set open . external-ids:ovn-remote=unix:/run/ovn/ovnsb_db.sock
ovs-vsctl set open . external-ids:ovn-encap-type=geneve
ovs-vsctl set open . external-ids:ovn-encap-ip=192.168.122.102
ovs-vsctl set open . external-ids:system-id=vm2

ovn-controller unix:/run/ovn/ovnsb_db.sock \
    --pidfile=/run/ovn/ovn-controller.pid \
    --log-file=/var/log/ovn/ovn-controller.log \
    --detach
```

### Verify chassis registration on both VMs

```bash
ovn-sbctl show
```

Expected output (on each VM, you'll see only the local chassis):

```text
Chassis "vm1"
    hostname: ovn-central
    Encap geneve
        ip: "192.168.122.101"
        options: {csum="true"}
```

## Step 8: Start IC Databases (VM1 Only)

The IC databases are centralized and hold transit switch definitions and
cross-zone route advertisements.

### On VM1 only

```bash
# Create IC database files
ovsdb-tool create /etc/ovn/ovn_ic_nb.db /usr/share/ovn/ovn-ic-nb.ovsschema
ovsdb-tool create /etc/ovn/ovn_ic_sb.db /usr/share/ovn/ovn-ic-sb.ovsschema

# Start IC-NB database server (TCP 6645 for remote access)
ovsdb-server /etc/ovn/ovn_ic_nb.db \
    --remote=punix:/run/ovn/ovn_ic_nb_db.sock \
    --remote=ptcp:6645:0.0.0.0 \
    --pidfile=/run/ovn/ovn_ic_nb_db.pid \
    --log-file=/var/log/ovn/ovn_ic_nb_db.log \
    --detach

# Start IC-SB database server (TCP 6646 for remote access)
ovsdb-server /etc/ovn/ovn_ic_sb.db \
    --remote=punix:/run/ovn/ovn_ic_sb_db.sock \
    --remote=ptcp:6646:0.0.0.0 \
    --pidfile=/run/ovn/ovn_ic_sb_db.pid \
    --log-file=/var/log/ovn/ovn_ic_sb_db.log \
    --detach
```

### Verify IC databases

```bash
ovn-ic-nbctl --db=unix:/run/ovn/ovn_ic_nb_db.sock ts-list
# Expected: empty (no transit switches yet)

ovn-ic-sbctl --db=unix:/run/ovn/ovn_ic_sb_db.sock list Availability_Zone
# Expected: empty (no zones registered yet)
```

## Step 9: Start ovn-ic Daemon

`ovn-ic` connects a zone's SB database to the IC databases. It:
1. Registers the zone in the IC-SB database
2. Watches for transit switches in IC-NB and creates local copies
3. Advertises local routes to IC-SB
4. Imports remote routes from IC-SB into the local zone

### On VM1 (local IC databases)

```bash
ovn-ic \
    --ic-nb-db=unix:/run/ovn/ovn_ic_nb_db.sock \
    --ic-sb-db=unix:/run/ovn/ovn_ic_sb_db.sock \
    --ovnsb-db=unix:/run/ovn/ovnsb_db.sock \
    --pidfile=/run/ovn/ovn-ic.pid \
    --log-file=/var/log/ovn/ovn-ic.log \
    --detach
```

### On VM2 (remote IC databases via TCP)

```bash
ovn-ic \
    --ic-nb-db=tcp:192.168.122.101:6645 \
    --ic-sb-db=tcp:192.168.122.101:6646 \
    --ovnsb-db=unix:/run/ovn/ovnsb_db.sock \
    --pidfile=/run/ovn/ovn-ic.pid \
    --log-file=/var/log/ovn/ovn-ic.log \
    --detach
```

### Verify IC zone registration (from VM1)

```bash
ovn-ic-sbctl --db=unix:/run/ovn/ovn_ic_sb_db.sock list Availability_Zone
```

Expected output — both zones registered:

```text
_uuid               : <uuid>
name                : "az1"

_uuid               : <uuid>
name                : "az2"
```

## Step 10: Verify the Full Stack

Run these checks on both VMs to confirm everything is operational.

### Process check

```bash
ps aux | grep -E 'ovs-vswitchd|ovsdb-server|ovn-northd|ovn-controller|ovn-ic' | grep -v grep
```

You should see (on VM1, 7 processes; on VM2, 5 processes):

| Process | VM1 | VM2 | Purpose |
|---------|-----|-----|---------|
| ovsdb-server (OVS DB) | ✓ | ✓ | OVS configuration database |
| ovs-vswitchd | ✓ | ✓ | OVS forwarding daemon |
| ovsdb-server (NB) | ✓ | ✓ | Zone Northbound database |
| ovsdb-server (SB) | ✓ | ✓ | Zone Southbound database |
| ovn-northd | ✓ | ✓ | NB→SB translator |
| ovn-controller | ✓ | ✓ | SB→OVS flow programmer |
| ovsdb-server (IC-NB) | ✓ | — | IC Northbound database |
| ovsdb-server (IC-SB) | ✓ | — | IC Southbound database |
| ovn-ic | ✓ | ✓ | Zone↔IC connector |

### Database check (on both VMs)

```bash
ovn-nbctl show          # empty — no logical entities yet
ovn-sbctl show          # shows local chassis
ovs-vsctl show          # shows br-int
ovs-ofctl dump-flows br-int  # minimal default flows
```

### Connectivity check

```bash
# From VM2, verify TCP connectivity to IC databases on VM1
ss -tnp | grep -E '6645|6646'
# Should show ESTABLISHED connections to 192.168.122.101
```

## What We Built

```text
VM1 (192.168.122.101)                    VM2 (192.168.122.102)
+------------------------------------+  +---------------------------+
| Zone: az1                          |  | Zone: az2                 |
|                                    |  |                           |
| NB DB ←→ northd ←→ SB DB          |  | NB DB ←→ northd ←→ SB DB |
|                     ↓              |  |                     ↓     |
|              ovn-controller        |  |              ovn-controller|
|                     ↓              |  |                     ↓     |
|                  br-int            |  |                  br-int   |
|                                    |  |                           |
| IC-NB DB ←→ ovn-ic ←→ SB DB       |  |      ovn-ic ←→ SB DB     |
| IC-SB DB ←-----------+            |  |        ↓                  |
|             ↑                      |  |   TCP to VM1:6645/6646   |
|             +-----------------------------→                      |
+------------------------------------+  +---------------------------+
```

## Troubleshooting

```bash
# Check OVN daemon logs
tail -50 /var/log/ovn/ovn-northd.log
tail -50 /var/log/ovn/ovn-controller.log
tail -50 /var/log/ovn/ovn-ic.log

# If a database fails to start, check if the socket/pid file already exists
ls -la /run/ovn/

# If ovn-controller can't connect, check SB socket
ovs-appctl -t /run/ovn/ovn-controller.*.ctl connection-status

# If ovn-ic can't connect to remote IC databases, verify firewall
firewall-cmd --list-ports
# If 6645/tcp and 6646/tcp are missing:
firewall-cmd --add-port=6645/tcp --add-port=6646/tcp
```

## Cleanup Script (if you need to start over)

```bash
# Stop all OVN daemons
kill $(cat /run/ovn/ovn-ic.pid 2>/dev/null) 2>/dev/null
kill $(cat /run/ovn/ovn-controller.pid 2>/dev/null) 2>/dev/null
kill $(cat /run/ovn/ovn-northd.pid 2>/dev/null) 2>/dev/null
kill $(cat /run/ovn/ovnnb_db.pid 2>/dev/null) 2>/dev/null
kill $(cat /run/ovn/ovnsb_db.pid 2>/dev/null) 2>/dev/null
kill $(cat /run/ovn/ovn_ic_nb_db.pid 2>/dev/null) 2>/dev/null
kill $(cat /run/ovn/ovn_ic_sb_db.pid 2>/dev/null) 2>/dev/null

# Remove databases
rm -f /etc/ovn/ovnnb_db.db /etc/ovn/ovnsb_db.db
rm -f /etc/ovn/ovn_ic_nb.db /etc/ovn/ovn_ic_sb.db

# Remove bridge
ovs-vsctl --if-exists del-br br-int

# Clean up run files
rm -f /run/ovn/*.sock /run/ovn/*.pid
```

---

**Next:** [Lab 02 — Logical Switch (Single Zone L2)](02-logical-switch.md)
