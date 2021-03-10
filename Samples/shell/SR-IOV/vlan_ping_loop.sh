for i in $(seq 1 100); do
    echo "Attempt #$i"
    oc delete -f sriov-pod1.yaml
    sleep 5
    oc apply -f sriov-pod1.yaml
    sleep 10
    oc exec -it sriovpod1 -- ip link add link test2 name f1 type vlan id 545
    oc exec -it sriovpod1 -- ip link set f1 up
    oc exec -it sriovpod1 -- ip link set test2 mtu 1500
    oc exec -it sriovpod1 -- ip link set f1 mtu 1500
    oc exec -it sriovpod1 -- ip addr add 10.110.203.27/26 dev f1

    oc exec -it sriovpod2 -- ip link add link test2 name f1 type vlan id 545
    oc exec -it sriovpod2 -- ip link set f1 up
    oc exec -it sriovpod2 -- ip link set test2 mtu 1500
    oc exec -it sriovpod2 -- ip link set f1 mtu 1500
    oc exec -it sriovpod2 -- ip addr add 10.110.203.24/26 dev f1

    sleep 2

    oc exec -it sriovpod1 -- ping -W1 -c 5 10.110.203.24
    rc=$?
    if [ $rc -ne 0 ]; then
        echo "Ping failed and issue reproduced"
        break
    fi
done

# cat sriov-pod1.yaml
# ---
# apiVersion: v1
# kind: Pod
# metadata:
#   name: sriovpod1
#   annotations:
#     k8s.v1.cni.cncf.io/networks: sriov-intel@test2
# spec:
#   containers:
#   - name: appcntr1
#     image: centos/tools
#     imagePullPolicy: IfNotPresent
#     command: [ "/bin/bash", "-c", "--" ]
#     args: [ "while true; do sleep 300000; done;" ]
#     securityContext:
#       capabilities:
#         add: ["NET_RAW", "NET_ADMIN"]
#       privileged: true

# ---

# apiVersion: v1
# kind: Pod
# metadata:
#   name: sriovpod2
#   annotations:
#     k8s.v1.cni.cncf.io/networks: sriov-intel@test2
# spec:
#   containers:
#   - name: appcntr1
#     image: centos/tools
#     imagePullPolicy: IfNotPresent
#     command: [ "/bin/bash", "-c", "--" ]
#     args: [ "while true; do sleep 300000; done;" ]
#     securityContext:
#       capabilities:
#         add: ["NET_RAW", "NET_ADMIN"]
#       privileged: true

####### Fast vs. Slow

pod1=sriovpod1
pod2=dpdk2
ip1=192.168.1.11/24
ip2=192.168.1.22/24

oc exec -it $pod1 -- ip link add link test2 name f1 type vlan id 545
oc exec -it $pod1 -- ip link set f1 up
oc exec -it $pod1 -- ip link set test2 mtu 1500
oc exec -it $pod1 -- ip link set f1 mtu 1500
oc exec -it $pod1 -- ip addr add $ip1 dev f1

oc exec -it $pod2 -- ip link add link tap0 name f1 type vlan id 545
oc exec -it $pod2 -- ip link set tap0 up
oc exec -it $pod2 -- ip link set tap0 mtu 1500
oc exec -it $pod2 -- ip link set f1 up
oc exec -it $pod2 -- ip link set f1 mtu 1500
oc exec -it $pod2 -- ip addr add $ip2 dev f1

sleep 2

oc exec -it $pod1 -- ping -W1 -c 5 `echo $ip2 | cut -d/ -f1`

###### SlowPaths

#oc exec -it sriovpod1 -- sysctl -w net.ipv4.conf.test2.arp_notify=0
oc exec -it sriovpod1 -- ip link add link test2 name f1 type vlan id 545
oc exec -it sriovpod1 -- ip link set f1 up
oc exec -it sriovpod1 -- ip link set test2 mtu 1500
oc exec -it sriovpod1 -- ip link set f1 mtu 1500
oc exec -it sriovpod1 -- ip addr add 10.110.203.27/26 dev f1

#oc exec -it sriovpod2 -- sysctl -w net.ipv4.conf.test2.arp_notify=0
oc exec -it sriovpod2 -- ip link add link test2 name f1 type vlan id 545
oc exec -it sriovpod2 -- ip link set f1 up
oc exec -it sriovpod2 -- ip link set test2 mtu 1500
oc exec -it sriovpod2 -- ip link set f1 mtu 1500
oc exec -it sriovpod2 -- ip addr add 10.110.203.24/26 dev f1

oc exec -it sriovpod1 -- ping -W1 -c 5 10.110.203.24

pod1=sriovpod1
pod2=dpdk
ip1=192.168.1.11/24
ip2=192.168.1.22/24

    oc exec -it $pod1 -- ip link add link test2 name f1 type vlan id 545
    oc exec -it $pod1 -- ip link set test2 up
    oc exec -it $pod1 -- ip link set f1 up
    oc exec -it $pod1 -- ip link set test2 mtu 1500
    oc exec -it $pod1 -- ip link set f1 mtu 1500
    oc exec -it $pod1 -- ip addr add $ip1 dev f1



    oc exec -it $pod2 -- ip link add link tap0 name f1 type vlan id 545
    oc exec -it $pod2 -- ip link set tap0 up
    oc exec -it $pod2 -- ip link set tap0 mtu 1500
    oc exec -it $pod2 -- ip link set f1 up
    oc exec -it $pod2 -- ip link set f1 mtu 1500
    oc exec -it $pod2 -- ip addr add $ip2 dev f1

sleep 1

oc exec -it $pod1 -- ping -W 1 -c 4 `echo $ip2 | cut -d/ -f1`