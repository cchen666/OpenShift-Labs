# LVM Partitions

## Create PV/VG/LVM and Filesystem

~~~bash
$ pvcreate /dev/sdb
$ vgcreate vg_var /dev/sdb
$ lvcreate -n lv_var -l 100%FREE vg_var
$ mkfs.xfs /dev/vg_var/lv_var
$ mkdir /dev/vg_var/lv_var
~~~

## Create the Mount File

Note: the file name has to be var-lib-containers.mount.

~~~bash
$ cat /etc/systemd/system/var-lib-containers.mount

[Unit]
Before=local-fs.target
[Mount]
What=/dev/vg_var/lv_var
Where=/var/lib/containers
Type=xfs
[Install]
WantedBy=local-fs.target
~~~

## Optional: Copy the /var/lib/containers content to LVM

~~~bash
$ mkdir /tmp/mnt
$ mount /dev/vg_var/lv_var /tmp/mnt
$ cp --preserve=mode,ownership,timestamps,context -rv /var/lib/containers/* /tmp/mnt/
~~~

## Reboot the Node
