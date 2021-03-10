#!/bin/bash
init(){
    VF1=1 # vf1
    VF2=2 # vf2
    VLAN=545

    PF=ens1f0

    IP1=10.110.203.27/26
    IP2=10.110.203.24/26

    NS1=ns1
    NS2=ns2
    ip netns delete $NS1
    ip netns delete $NS2
    sleep 1
}

setup(){

    ip netns add $NS1
    ip netns add $NS2

    ip link set dev ${PF}v${VF1} netns $NS1
    ip netns exec $NS1 ip link add link ${PF}v${VF1} name f1 type vlan id $VLAN
    ip netns exec $NS1 ip link set ${PF}v${VF1} up
    ip netns exec $NS1 ip link set f1 up
    ip netns exec $NS1 ip addr add ${IP1} dev f1

    sleep 1

    ip link set dev ${PF}v${VF2} netns $NS2
    ip netns exec $NS2 ip link add link ${PF}v${VF2} name f1 type vlan id $VLAN
    ip netns exec $NS2 ip link set ${PF}v${VF2} up
    ip netns exec $NS2 ip link set f1 up
    ip netns exec $NS2 ip addr add ${IP2} dev f1

    sleep 1

}

cleanup(){

    ip netns delete $NS1
    ip netns delete $NS2
}

doTest() {

    for i in $(seq 1 100); do
        cleanup
        setup
        echo "Attempt #$i"
        ip netns exec $NS1 ping -c5 `echo $IP2 | cut -d/ -f 1`
        rc=$?
        if [ $? -ne 0 ]; then
            echo "Ping failed, issue might reproduce"
            cleanup
            break
        fi
    done
    cleanup
}

init
doTest
