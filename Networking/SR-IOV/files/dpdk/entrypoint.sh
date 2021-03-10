PCI=$(env | grep PCI | cut -d= -f2)
MAC=$(echo "macaddr 0" | /dpdk-ethtool -a $PCI | awk '/Port 0 MAC Address/ {print $NF}')
( echo 'start' ; while true ; do echo 'show port stats all' ; sleep 60 ; done ) | /dpdk-testpmd -n 4 -l `cat /sys/fs/cgroup/cpuset/cpuset.cpus` -a $PCI --socket-mem 1024 --vdev=virtio_user0,path=/dev/vhost-net,mac=$MAC -- -i
sleep infinity