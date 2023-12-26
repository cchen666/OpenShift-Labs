#!/bin/bash
mon_endpoints="10.0.169.5:6789"
my_secret=$(grep key /etc/ceph/ceph.client.admin.keyring | awk '{print $3}')
for i in 1 2
do
        ceph fs subvolume create ocs-storagecluster-cephfilesystem test$i csi
        path=$(ceph fs subvolume getpath ocs-storagecluster-cephfilesystem test$i csi)
        mkdir -p /tmp/registry$i
        mount -t ceph -o mds_namespace=ocs-storagecluster-cephfilesystem,name=admin,secret=$my_secret $mon_endpoints:/$path /tmp/registry$i
        chgrp 9999 /tmp/registry$i
        chmod g+s,a+rwx /tmp/registry$i
        mkdir -p /tmp/registry$i/a
        mkdir -p /tmp/registry$i/b
        mkdir -p /tmp/registry$i/c
        mkdir -p /tmp/registry$i/d
        ls -lrt /tmp/registry$i
        umount /tmp/registry$i
        ceph fs subvolume rm ocs-storagecluster-cephfilesystem test$i csi
done