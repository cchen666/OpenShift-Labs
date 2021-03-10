# Known Issues

## Importer Pod stuck in "Validating image" Forever

### Issue

~~~log
$ oc logs importer-rhel8u6-rootdisk-k5r33 -f
I1009 13:25:59.810028       1 importer.go:83] Starting importer
I1009 13:25:59.810738       1 importer.go:138] begin import process
I1009 13:26:00.956809       1 data-processor.go:340] Calculating available size
I1009 13:26:00.957810       1 data-processor.go:352] Checking out file system volume size.
I1009 13:26:00.958118       1 data-processor.go:360] Request image size not empty.
I1009 13:26:00.958131       1 data-processor.go:365] Target size 34087042032.
I1009 13:26:00.959669       1 nbdkit.go:294] Waiting for nbdkit PID.
I1009 13:26:01.460603       1 nbdkit.go:315] nbdkit ready.
I1009 13:26:01.460627       1 data-processor.go:243] New phase: Convert
I1009 13:26:01.460650       1 data-processor.go:249] Validating image
I1009 13:26:01.477740       1 qemu.go:257] 0.00
~~~

### Diagnose

1. Check corresonding command to validate the image

    ~~~bash
    $ oc rsh importer-rhel8u6-rootdisk-k5r33
    sh-4.4# cat /proc/18/cmdline
    qemu-imgconvert-twriteback-p-Orawnbd+unix:///?socket=/var/run/nbdkit.sock/data/disk.imgsh-4.4#

    # We know the command is the following

    sh-4.4# qemu-img convert -t writeback -p -O raw nbd+unix:///?socket=/var/run/nbdkit.sock /data/disk.img
    ^C  (0.00/100%) # This command hang forever
    ~~~

2. Run the command outside the container and found the command also hangs

    ~~~bash
    $ mount -t nfs localhost:/var/nfsshare /mnt/
    $ qemu-img convert -t writeback -p -O raw /var/www/html/iso/rhel-8.6-kvm.qcow2 /mnt/4.img
    ^C  (0.00/100%)
    ~~~

3. Change NFS server configuration to the following

    ~~~bash
    /var/nfsshare     *(rw,sync,no_root_squash)
    ~~~

4. Restart the NFS and NFS provisionor Pod

    ~~~bash
    $ systemctl restart nfs-server
    $ oc delete pod -n openshift-nfs-storage --all
    ~~~

5. The error inside importer Pod is gone and VM is running

## VMI is Not Created

<https://github.com/kubevirt/containerized-data-importer/blob/main/doc/storageprofile.md>

~~~bash

$ oc get ev

<Snip>
4m50s       Warning   ErrClaimNotValid             datavolume/rhel8-minor-bird                DataVolume.storage spec is missing accessMode and volumeMode, cannot get access mode from StorageProfile standard-csi

~~~

Need to patch the StorageProfile of the StorageClass with both accessModes and volumeMode set.

~~~bash

$ oc get storageprofile standard-csi -o yaml

<Snip>
spec:
  claimPropertySets:
  - accessModes:
    - ReadWriteOnce

$ oc patch --type merge -p '{"spec": {"claimPropertySets": [{"volumeMode": "Filesystem"}]}}' StorageProfile standard-csi

$ oc get storageprofile standard-csi -o yaml

<Snip>
spec:
  claimPropertySets:
  - accessModes:
    - ReadWriteOnce
    volumeMode: Filesystem

~~~
