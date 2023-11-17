#!/bin/bash

# Number of attempts
attempts=1

# Sleep interval in seconds
sleep_interval=5

delete_ovs_on_masters() {

for MASTER in $(oc get nodes -l node-role.kubernetes.io/master= -o name --no-headers); \
do echo "Deleting databases on master $MASTER" ; \
oc debug $MASTER -- chroot /host /bin/bash -c  'rm -f /var/lib/ovn/etc/*.db' ; sleep 3; \
done

}

delete_master_pods() {
oc -n openshift-ovn-kubernetes delete pod -l=app=ovnkube-master
}

# Restart OVS services on master nodes
restart_ovs_on_masters() {
    for MASTER in $(oc get nodes -l node-role.kubernetes.io/master= -o name --no-headers); do
        echo "Restarting OVS services on node $MASTER"
        oc debug $MASTER -- chroot /host /bin/bash -c 'systemctl restart ovs-vswitchd ovsdb-server'
        sleep 2
    done
}

check_leader() {
for OVNMASTER in $(oc -n openshift-ovn-kubernetes get pods -l app=ovnkube-master -o custom-columns=NAME:.metadata.name --no-headers); \
   do echo "········································" ; \
   echo "· OVNKube Master: $OVNMASTER ·" ; \
   echo "········································" ; \
   echo 'North' `oc -n openshift-ovn-kubernetes rsh -Tc northd $OVNMASTER ovn-appctl -t /var/run/ovn/ovnnb_db.ctl cluster/status OVN_Northbound | grep Role` ; \
   echo 'South' `oc -n openshift-ovn-kubernetes rsh -Tc northd $OVNMASTER ovn-appctl -t /var/run/ovn/ovnsb_db.ctl cluster/status OVN_Southbound | grep Role`; \
   echo "····················"; \
   done
}

# Main loop
for i in $(seq 1 $attempts); do
    sleep $sleep_interval
    echo "Attempt $i"

    delete_ovs_on_masters

    sleep $sleep_interval

    delete_master_pods

    sleep 400

    check_leader
    sleep $sleep_interval
    restart_ovs_on_masters

    sleep $sleep_interval
    oc whoami
    rc=$?

    # Check if 'oc whoami' returned a non-zero exit code, and break if true
    if [ $rc -ne 0 ]; then
        break
    fi
done