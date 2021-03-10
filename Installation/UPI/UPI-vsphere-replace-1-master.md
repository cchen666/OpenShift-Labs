# Replace 1 Failed Master Node

## Backup ETCD First

~~~bash

$ oc debug node/<Working Node>
$ chroot /host
$ /usr/local/bin/cluster-backup.sh /home/core/assets/backup

~~~

## Delete the Failed Node

~~~bash

$ oc rsh -n openshift-etcd <Working Pod>
sh-4.2# etcdctl member list -w table # Remember the Failed Node ID
sh-4.2# etcdctl member remove <Failed Node ID>
$ oc get secrets -n openshift-etcd | grep <Failed Node>
$ oc delete secrets <All three Failed Node Secrets>

~~~

## Recreate the Failed Master Node in IaaS Level and Approve CSR

~~~bash

$ oc get csr -o name | xargs oc adm certificate approve

~~~

## Force Redeployment of etcd, kube-apiserver, scheduler, controller-manager if not Created

~~~bash

# It could happen that the static PODs manifests are not created automatically
$ oc patch etcd cluster -p='{"spec": {"forceRedeploymentReason": "recovery-'"$( date --rfc-3339=ns )"'"}}' --type=merge
$ oc patch kubeapiserver cluster -p='{"spec": {"forceRedeploymentReason": "recovery-'"$( date --rfc-3339=ns )"'"}}' --type=merge
$ oc patch kubecontrollermanager cluster -p='{"spec": {"forceRedeploymentReason": "recovery-'"$( date --rfc-3339=ns )"'"}}' --type=merge
$ oc patch kubescheduler cluster -p='{"spec": {"forceRedeploymentReason": "recovery-'"$( date --rfc-3339=ns )"'"}}' --type=merge

~~~
