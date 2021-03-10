# Local Storage Operator

## Create LocalVolume CR

~~~bash
$ oc apply files/LocalVolume.yaml
~~~

## Create Pod

~~~bash
$ oc apply -f files/pod.yaml
$ oc get pods
NAME    READY   STATUS    RESTARTS   AGE
rhel7   1/1     Running   15         15h

$ oc rsh rhel7
sh-4.2# ls /data/ | wc -l
0

sh-4.2# cd /data
sh-4.2# touch a b c d e f g
~~~

## Verify the files created in PV exists even deleting the POD

~~~bash
$ oc delete pod rhel7
$ oc apply files/pod.yaml
$ oc rsh rhel7
sh-4.2# ls /data/
a  b  c  d  e  f  g
~~~

## Further Look

~~~bash

# Kubelet Logs

Apr 11 13:18:18 ip-10-0-150-204 hyperkube[1819]: I0411 13:18:18.105182    1819 mount_linux.go:425] Disk "/mnt/local-storage/local-sc/nvme-Amazon_Elastic_Block_Store_vol03b41e4841132a96b" appears to be unformatted, attempting to format as type: "xfs" with options: [/mnt/local-storage/local-sc/nvme-Amazon_Elastic_Block_Store_vol03b41e4841132a96b]
Apr 11 13:18:18 ip-10-0-150-204 hyperkube[1819]: I0411 13:18:18.345534    1819 mount_linux.go:435] Disk successfully formatted (mkfs): xfs - /mnt/local-storage/local-sc/nvme-Amazon_Elastic_Block_Store_vol03b41e4841132a96b /var/lib/kubelet/plugins/kubernetes.io/local-volume/mounts/local-pv-6abafcd5
Apr 11 13:18:18 ip-10-0-150-204 hyperkube[1819]: I0411 13:18:18.398151    1819 operation_generator.go:616] MountVolume.MountDevice succeeded for volume "local-pv-6abafcd5" (UniqueName: "kubernetes.io/local-volume/local-pv-6abafcd5") pod "rhel7" (UID: "533d00bb-9bcd-4866-ade9-07f7cdea752f") device mount path "/var/lib/kubelet/plugins/kubernetes.io/local-volume/mounts/local-pv-6abafcd5"

# Login to Worker and verify

$ oc debug node/<worker node>

sh-4.4# file /mnt/local-storage/local-sc/nvme-Amazon_Elastic_Block_Store_vol03b41e4841132a96b
/mnt/local-storage/local-sc/nvme-Amazon_Elastic_Block_Store_vol03b41e4841132a96b: symbolic link to /dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_vol03b41e4841132a96b
sh-4.4# ls -l /dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_vol03b41e4841132a96b
lrwxrwxrwx. 1 root root 13 Apr 11 13:18 /dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_vol03b41e4841132a96b -> ../../nvme1n1
sh-4.4#

# Even the PVC we specified is 50Gi, since the LocalVolume is 100Gi, the PVC is 100Gi

$ oc get pvc
NAME             STATUS   VOLUME              CAPACITY   ACCESS MODES   STORAGECLASS   AGE
local-pvc-name   Bound    local-pv-6abafcd5   100Gi      RWO            local-sc       16h
sh-4.2# df -h
Filesystem      Size  Used Avail Use% Mounted on
overlay         120G   15G  105G  13% /
tmpfs            64M     0   64M   0% /dev
tmpfs            16G     0   16G   0% /sys/fs/cgroup
shm              64M     0   64M   0% /dev/shm
tmpfs            16G   61M   16G   1% /etc/hostname
/dev/nvme1n1    100G  747M  100G   1% /data  # <==========
/dev/nvme0n1p4  120G   15G  105G  13% /etc/hosts
tmpfs            16G   20K   16G   1% /run/secrets/kubernetes.io/serviceaccount
tmpfs            16G     0   16G   0% /proc/acpi
tmpfs            16G     0   16G   0% /proc/scsi
tmpfs            16G     0   16G   0% /sys/firmware
~~~
