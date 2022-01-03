#### Get networks
~~~
$ oc get networks


networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  networkType: OpenShiftSDN  <<------------  OpenShift network plug-in name
  serviceNetwork:
  - 172.30.0.0/16

clusterNetwork cidr: A cluster wide range/block of IP addresses from which Pod IP addresses are allocated.
10.128.0.0/14 ; Network range - 10.128.0.0 - 10.131.255.255
Addresses in network - 262144

hostPrefix: The subnet prefix length to assign to each individual node.
 10.128.0.0/23 ; Network range - 10.128.0.0 - 10.128.1.255
Addresses in network - 512
262144 ÷ 512 = 512 (approximate number of nodes)
serviceNetwork cidr: The IP address pool to use for service IP addresses.
172.30.0.0/16 ; Network range- 172.30.0.0 - 172.30.255.255
Addresses in network - 65536

$ oc get hostsubnet
NAME                                         HOST                                         HOST IP        SUBNET          EGRESS CIDRS   EGRESS IPS
ip-10-0-130-137.us-east-2.compute.internal   ip-10-0-130-137.us-east-2.compute.internal   10.0.130.137   10.129.0.0/23                  
ip-10-0-157-89.us-east-2.compute.internal    ip-10-0-157-89.us-east-2.compute.internal    10.0.157.89    10.128.2.0/23                  
ip-10-0-162-179.us-east-2.compute.internal   ip-10-0-162-179.us-east-2.compute.internal   10.0.162.179   10.131.0.0/23                  
ip-10-0-187-180.us-east-2.compute.internal   ip-10-0-187-180.us-east-2.compute.internal   10.0.187.180   10.128.0.0/23                  
ip-10-0-199-90.us-east-2.compute.internal    ip-10-0-199-90.us-east-2.compute.internal    10.0.199.90    10.130.0.0/23

Each node will get a unique subnet.

~~~
