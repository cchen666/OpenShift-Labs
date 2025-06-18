# Install Ceph All in One

* For installation

<https://www.redhat.com/sysadmin/ceph-cluster-single-machine>

* For post-installation configuration

<<https://www.highgo.ca/2023/03/24/setup-an-all-in-one-ceph-storage-cluster-on-one-machine/>

## Installation

```bash

$ ip=a.b.c.d
$ sudo subscription-manager repos --enable=rhceph-5-tools-for-rhel-8-x86_64-rpms
$ sudo dnf install podman cephadm ceph-common ceph-base -y
$ sudo cephadm bootstrap --cluster-network 10.0.169.0/24 \
--mon-ip $ip \
--registry-url registry.redhat.io \
--registry-username 'rhn-support-cchen' \
--registry-password 'XXXXXX' \
--dashboard-password-noupdate \
--initial-dashboard-user admin \
--initial-dashboard-password redhat \
--allow-fqdn-hostname --single-host-defaults

```

## Add Disks to Ceph

```bash

$ sudo ceph orch apply osd --all-available-devices

```

## Configuration

### Create rbd

```bash

$ sudo ceph osd pool create rbd
$ sudo ceph osd pool application enable rbd rbd

$ sudo rbd create mysql --size 1G
$ sudo rbd create mongodb --size 2G

$ sudo rbd list
```

### Create CephFS

```bash

$ ceph fs volume create ocs-storagecluster-cephfilesystem csi
$ ceph fs subvolume create ocs-storagecluster-cephfilesystem test1 csi

```
