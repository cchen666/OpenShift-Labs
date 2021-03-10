for pv in `oc get pv | grep Released | awk '{print $1}'`; do
    disks="$disks `oc get pv $pv -o jsonpath='{.spec.local.path}'`"
    oc delete $pv
done
systemctl restart kubelet
for disk in $disks; do
    mkfs -F $disk
    wipefs -a $disk
done