# OVN Kubernetes Database

## [DRAFT] Useful Commands

```bash

$ oc rsh ovnkube-master
sh-4.4# ovn-nbctl list Logical_Switch | grep name | sort
name                : ext_gcg-shift-98bcz-master-0
name                : ext_gcg-shift-98bcz-master-1
name                : ext_gcg-shift-98bcz-master-2
name                : ext_gcg-shift-98bcz-worker-0-jjbdk
name                : ext_gcg-shift-98bcz-worker-0-l8wn9
name                : ext_gcg-shift-98bcz-worker-0-ls68r
name                : gcg-shift-98bcz-master-0
name                : gcg-shift-98bcz-master-1
name                : gcg-shift-98bcz-master-2
name                : gcg-shift-98bcz-worker-0-jjbdk
name                : gcg-shift-98bcz-worker-0-l8wn9
name                : gcg-shift-98bcz-worker-0-ls68r
name                : join


sh-4.4# ovn-nbctl list Logical_Switch_Port


sh-4.4# ovn-nbctl list Logical_Router | grep name | sort
name                : GR_gcg-shift-98bcz-master-0
name                : GR_gcg-shift-98bcz-master-1
name                : GR_gcg-shift-98bcz-master-2
name                : GR_gcg-shift-98bcz-worker-0-jjbdk
name                : GR_gcg-shift-98bcz-worker-0-l8wn9
name                : GR_gcg-shift-98bcz-worker-0-ls68r
name                : ovn_cluster_router

sh-4.4# ovn-nbctl list port-group
sh-4.4# ovn-nbctl list acl
sh-4.4# ovn-nbctl list Load_Balancer

sh-4.4# ovn-nbctl show b3b795ef-6976-4dbf-a477-932113b9a9f5

```
