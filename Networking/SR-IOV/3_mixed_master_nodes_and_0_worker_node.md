# Overview

These post configuraiton steps used for 3 mixed master nodes + 0 worker node OCP (OpenShift Cloud Platform).

## Configuration Steps

+ Login OCP cluster management jump server

+ Configure OCP cluster management token, skip this step if you already done

  ```bash
  Copy OCP cluster management token from https://cloud.redhat.com/openshift/token/show with your RedHat account

  [root@ocp-manage-repo ~]# token=ocp_clusters_management_token
  [root@ocp-manage-repo ~]# echo "export AI_OFFLINETOKEN=${token}" >> ~/.bashrc && source ~/.bashrc
  ```

+ Install kubectl and oc (OpenShift CLI) binaries, skip this step if you already done

  ```bash
  [root@ocp-manage-repo ~]# wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz
  [root@ocp-manage-repo ~]# tar -xvzf openshift-client-linux.tar.gz -C /usr/local/bin && rm -f openshift-client-linux.tar.gz
  [root@ocp-manage-repo ~]# echo "source <(kubectl completion bash)" >>  ~/.bashrc
  [root@ocp-manage-repo ~]# echo "source <(oc completion bash)" >>  ~/.bashrc
  [root@ocp-manage-repo ~]# source ~/.bashrc
  ```

+ Download kubeconfig file of target OCP cluster and set KUBECONFIG environment variable

  ```bash
  Get target OCP cluster name with `aicli list clusters` command or OCP cluster management dashboard

  [root@ocp-manage-repo ~]# cluster_name=target_ocp_cluster_name
  [root@ocp-manage-repo ~]# aicli download kubeconfig ${cluster_name}
  [root@ocp-manage-repo ~]# export KUBECONFIG=/your_ocp_kubeconfig_file_path/target_ocp_kubeconfig_file
  ```

+ Configure local DNS domain for target OCP cluster

  ```bash
  Get target OCP cluster name and base DNS domain with `aicli list clusters` command or OCP cluster management dashboard

  [root@ocp-manage-repo ~]# cluster_name=target_ocp_cluster_name
  [root@ocp-manage-repo ~]# cluster_base_domain=target_ocp_cluster_base_domain
  [root@ocp-manage-repo ~]# cluster_ip=$(aicli info cluster ${cluster_name} -f api_vip -v |grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
  [root@ocp-manage-repo ~]# echo "${cluster_ip}  api.${cluster_name}.${cluster_base_domain} oauth-openshift.apps.${cluster_name}.${cluster_base_domain}" >> /etc/hosts
  ```

+ Check if kubectl or oc cmd can get expected output

  ```bash
  [root@ocp-manage-repo ~]# kubectl get nodes
  NAME                            STATUS   ROLES           AGE   VERSION
  hztt24f-rm17-ocp-01-master-01   Ready    master,worker   26d   v1.21.1+f36aa36
  hztt24f-rm17-ocp-01-master-02   Ready    master,worker   26d   v1.21.1+f36aa36
  hztt24f-rm17-ocp-01-master-03   Ready    master,worker   26d   v1.21.1+f36aa36

  [root@ocp-manage-repo ~]# oc get nodes
  NAME                            STATUS   ROLES           AGE   VERSION
  hztt24f-rm17-ocp-01-master-01   Ready    master,worker   26d   v1.21.1+f36aa36
  hztt24f-rm17-ocp-01-master-02   Ready    master,worker   26d   v1.21.1+f36aa36
  hztt24f-rm17-ocp-01-master-03   Ready    master,worker   26d   v1.21.1+f36aa36
  ```

+ Download ocp-om reposity

  ```bash
  [root@ocp-manage-repo ~]# git clone https://gitlabe2.ext.net.nokia.com/cloud-infra/ocp-om.git
  ```

+ Configure related parameters of cluster.yml in ocp-om/playbooks folder accorinding to your OCP deployment and HW type

    Some example post configuration files can be used for your reference:
    - [multi_nodes_oe19_20_cores_one_socket_intel_700_nic_ht_off](https://gitlabe2.ext.net.nokia.com/cloud-infra/ocp-om/-/blob/master/yamls/multi_nodes_oe19_20_cores_intel_700_ht_off.yml)
    - [multi_nodes_oe20_32_cores_one_socket_intel_800_nic_ht_off](https://gitlabe2.ext.net.nokia.com/cloud-infra/ocp-om/-/blob/master/yamls/multi_nodes_oe20_32_cores_intel_800_ht_off.yml)
    - [multi_nodes_rm17_20_cores_two_sockets_mlx_cx4/5_nic_ht_on](https://gitlabe2.ext.net.nokia.com/cloud-infra/ocp-om/-/blob/master/yamls/multi_nodes_rm17_20_cores_ht_on.yml)
    - [multi_nodes_rm17_20_cores_two_sockets_mlx_cx4/5_nic_ht_off](https://gitlabe2.ext.net.nokia.com/cloud-infra/ocp-om/-/blob/master/yamls/multi_nodes_rm17_20_cores_ht_off.yml)
    - [multi_nodes_rm17_28_cores_two_sockets_mlx_cx4/5_nic_ht_on](https://gitlabe2.ext.net.nokia.com/cloud-infra/ocp-om/-/blob/master/yamls/multi_nodes_rm17_28_cores_ht_on.yml)
    - [multi_nodes_rm17_28_cores_two_sockets_mlx_cx4/5_nic_ht_off](https://gitlabe2.ext.net.nokia.com/cloud-infra/ocp-om/-/blob/master/yamls/multi_nodes_rm17_28_cores_ht_off.yml)

    - [multi_nodes_rm18_40_cores_two_sockets_mlx_cx4/5_nic_ht_on](https://gitlabe2.ext.net.nokia.com/cloud-infra/ocp-om/-/blob/master/yamls/multi_nodes_rm18_40_cores_ht_on.yml)
    - [multi_nodes_rm18_40_cores_two_sockets_mlx_cx4/5_nic_ht_off](https://gitlabe2.ext.net.nokia.com/cloud-infra/ocp-om/-/blob/master/yamls/multi_nodes_rm18_40_cores_ht_off.yml)
+ Run playbooks with tag one by one in ocp-om/playbooks folder

    - [root@ocp-manage-repo ~]# ./01-playbook.yaml --tags apply-01 -vv -e '{kernel_modules_nodeselector: master}' #Load required kernel modules, including sctp, vhost-net, etc. `One time restart`

      ```bash
      Check the output of `oc get mcp master` until UPDATING status changed from True to False and READYMACHINECOUNT same as MACHINECOUNT

      [root@ocp-manage-repo ~]# oc get mcp master
      ```

    - [root@ocp-manage-repo ~]# ./01-playbook.yaml --tags apply-02 -vv   #Deploy NFD(Node Feature Discovery) operator to add host labels, e.g. OS version, CPU attributes, etc.

      ```bash
      [root@ocp-manage-repo ~]# kubectl get pod -n openshift-nfd
      NAME                            READY   STATUS    RESTARTS   AGE
      nfd-master-pjjc5                1/1     Running   5          25d
      nfd-master-vkkz4                1/1     Running   6          25d
      nfd-master-x5fnl                1/1     Running   8          25d
      nfd-operator-5bd6d4786b-2q8g5   1/1     Running   0          19d
      nfd-worker-4wkj2                1/1     Running   7          25d
      nfd-worker-8gz8j                1/1     Running   10         25d
      nfd-worker-kdlp4                1/1     Running   5          25d

      ```

    - [root@ocp-manage-repo ~]# ./01-playbook.yaml --tags apply-03 -vv   #Deploy SR-IOV operator

      ```bash
      [root@ocp-manage-repo ~]# kubectl get pod -n openshift-sriov-network-operator
      NAME                                     READY   STATUS    RESTARTS   AGE
      operator-webhook-8qkn6                   1/1     Running   0          43h
      operator-webhook-p22x7                   1/1     Running   0          43h
      operator-webhook-pdvq5                   1/1     Running   0          43h
      sriov-network-config-daemon-blxx9        1/1     Running   0          43h
      sriov-network-config-daemon-dm4p9        1/1     Running   0          43h
      sriov-network-config-daemon-wl6n7        1/1     Running   0          43h
      sriov-network-operator-8cbf66595-cqndr   1/1     Running   0          43h

      ```

    - [root@ocp-manage-repo ~]# ./01-playbook.yaml --tags apply-04 -vv   #Deploy SR-IOV device pool. `Two times restart`

      ```bash
      [root@ocp-manage-repo ~]# kubectl get pod -n openshift-sriov-network-operator
      NAME                                     READY   STATUS    RESTARTS   AGE
      operator-webhook-8qkn6                   1/1     Running   0          43h
      operator-webhook-p22x7                   1/1     Running   0          43h
      operator-webhook-pdvq5                   1/1     Running   0          43h
      sriov-cni-7bpzc                          2/2     Running   0          43h
      sriov-cni-jbdp8                          2/2     Running   0          43h
      sriov-cni-phzmm                          2/2     Running   0          43h
      sriov-device-plugin-gsv4t                1/1     Running   0          43h
      sriov-device-plugin-jpmqh                1/1     Running   0          43h
      sriov-device-plugin-st8f9                1/1     Running   0          43h
      sriov-network-config-daemon-blxx9        1/1     Running   0          43h
      sriov-network-config-daemon-dm4p9        1/1     Running   0          43h
      sriov-network-config-daemon-wl6n7        1/1     Running   0          43h
      sriov-network-operator-8cbf66595-cqndr   1/1     Running   0          43h

      ```

    - [root@ocp-manage-repo ~]# ./01-playbook.yaml --tags apply-05 -vv -e '{pao_profile_nodeselector: master}'    #Deploy PAO (Performance Addon Operator) to config performance profiles, e.g. CPU manager, CPU isolation, hugepage, etc. `Two times restart`

      ```bash
      Check the output of `oc get mcp master` until UPDATING status changed from True to False and READYMACHINECOUNT same as MACHINECOUNT

      [root@ocp-manage-repo ~]# oc get mcp master
      ```

    - [root@ocp-manage-repo ~]# ./01-playbook.yaml --tags apply-06 -vv    #Deploy PTP service, only needed for OE based vDU (C-RAN)

      ```bash
      [root@ocp-manage-repo new_sno]# kubectl get pod -n openshift-ptp
      NAME                           READY   STATUS    RESTARTS   AGE
      linuxptp-daemon-g2wrl          2/2     Running   0          9h
      linuxptp-daemon-q84x4          2/2     Running   0          9h
      linuxptp-daemon-sc6pg          2/2     Running   0          9h
      linuxptp-daemon-v2mfx          2/2     Running   0          9h
      linuxptp-daemon-vxd55          2/2     Running   0          9h
      ptp-operator-77f84587c-79tc4   1/1     Running   0          9h
      ```

    - [root@ocp-manage-repo ~]# ./01-playbook.yaml --tags apply-08 -vv    #Configure admin user (nokiaadmin/nokiaadmin)

    - [root@ocp-manage-repo ~]# ./01-playbook.yaml --tags apply-09 -vv -e '{unsafe_sysctls_nodeselector: master}'    #Configure unsafe sysctl parameters. `Two times restart`

      ```bash
      Check the output of `oc get mcp master` until UPDATING status changed from True to False and READYMACHINECOUNT same as MACHINECOUNT

      [root@ocp-manage-repo ~]# oc get mcp master
      ```

    - Workaround to enable unsafe sysctls configuration for mixed master nodes via delete created profile and repeat step 9

      ```bash
      [root@ocp-manage-repo ~]# oc delete kubeletconfigs.machineconfiguration.openshift.io performance-sysctl-master
      [root@ocp-manage-repo ~]# ./01-playbook.yaml --tags apply-09 -vv -e '{unsafe_sysctls_nodeselector: master}'  #Configure unsafe sysctls parameters for mixed master nodes. `Two times restart`

      Check the output of `oc get mcp master` until UPDATING status changed from True to False and READYMACHINECOUNT same as MACHINECOUNT

      [root@ocp-manage-repo ~]# oc get mcp master

    - [root@ocp-manage-repo ~]# ./01-playbook.yaml --tags apply-10 -vv    #Configure local image registry
