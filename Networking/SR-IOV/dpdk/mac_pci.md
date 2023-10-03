# Output MAC and PCI inside the Pod

## Download dpdk and compile

```bash

$ curl -o dpdk.tar.xz https://fast.dpdk.org/rel/dpdk-21.11.tar.xz
$ tar -xf dpdk.tar.xz
$ cd dpdk-21.11

$ meson -Dplatform=generic build
$ cd build
$ mkdir ../example/mac
$ cp files/pci_mac.c ../examples/main.c
$ cp ../examples/vdpa/Makefile ../examples/mac/
$ cp ../examples/vdpa/meson.build ../examples/mac

$ meson configure -Dexamples=mac
$ ninja

```

## Copy the dpdk-mac to the Pod and Verify

```bash

sh-4.4# ./dpdk-mac  --legacy-mem
EAL: Detected CPU lcores: 32
EAL: Detected NUMA nodes: 2
EAL: Static memory layout is selected, amount of reserved memory can be adjusted with -m or --socket-mem
EAL: Detected static linkage of DPDK
EAL: Multi-process socket /var/run/dpdk/rte/mp_socket
EAL: Selected IOVA mode 'VA'
EAL: No available 2048 kB hugepages reported
EAL: VFIO support initialized
EAL: Failed to open VFIO group 102
EAL: 0000:82:12.0 not managed by VFIO driver, skipping
EAL: Failed to open VFIO group 103
EAL: 0000:82:12.2 not managed by VFIO driver, skipping
EAL: Failed to open VFIO group 104
EAL: 0000:82:12.4 not managed by VFIO driver, skipping
EAL: Failed to open VFIO group 105
EAL: 0000:82:12.6 not managed by VFIO driver, skipping
EAL: Failed to open VFIO group 106
EAL: 0000:82:13.0 not managed by VFIO driver, skipping
EAL: Using IOMMU type 1 (Type 1)
EAL: Probe PCI driver: net_ixgbe_vf (8086:10ed) device: 0000:82:13.2 (socket 1)
EAL: Failed to open VFIO group 108
EAL: 0000:82:13.4 not managed by VFIO driver, skipping
EAL: Failed to open VFIO group 109
EAL: 0000:82:13.6 not managed by VFIO driver, skipping
TELEMETRY: No legacy callbacks, legacy socket not created
Number of available Ethernet devices: 1
Device PCI: 0000:82:13.2
MAC Address: 3A:96:75:4F:4B:FF

```
