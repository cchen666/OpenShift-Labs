for i in 0 1 2; do
virsh destroy ocp-master-$i
virsh undefine ocp-master-$i
rm -rf /home/sno/images/ocp-master-$i.qcow2
done

for i in 0 1 2; do
virsh destroy ocp-worker-$i
virsh undefine ocp-worker-$i
rm -rf /home/sno/images/ocp-worker-$i.qcow2
done