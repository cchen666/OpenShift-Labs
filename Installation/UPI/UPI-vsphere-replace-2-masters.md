# Replace 2 Failed Masters

## Restore ETCD Backup on Working Node

~~~bash

$ sudo -E /usr/local/bin/cluster-restore.sh /home/core/assets/backup
$ sudo systemctl restart kubelet.service

~~~

## Recreate 2 Failed Masters and Approve CSRs

~~~bash

$ oc get csr -o name | xargs oc adm certificate approve

~~~

## Force Redeployment of ETCD

~~~bash

$ oc patch etcd cluster -p='{"spec": {"forceRedeploymentReason": "recovery-'"$( date --rfc-3339=ns )"'"}}' --type=merge

~~~

## Force Redeployment of kube-apiserver, scheduler and controller-manager

~~~bash

$ oc patch kubeapiserver cluster -p='{"spec": {"forceRedeploymentReason": "recovery-'"$( date --rfc-3339=ns )"'"}}' --type=merge
$ oc patch kubecontrollermanager cluster -p='{"spec": {"forceRedeploymentReason": "recovery-'"$( date --rfc-3339=ns )"'"}}' --type=merge
$ oc patch kubescheduler cluster -p='{"spec": {"forceRedeploymentReason": "recovery-'"$( date --rfc-3339=ns )"'"}}' --type=merge

~~~
