# ETCD

## Election/Heartbeat Flow

<http://thesecretlivesofdata.com/>

## Official learning material

<https://github.com/etcd-io/etcd/tree/release-3.4/Documentation/learning>
<https://github.com/etcd-io/etcd/tree/release-3.4/Documentation/faq.md>

## Get all the keys

<https://github.com/peterducai/etcd-tools/blob/main/etcd-analyzer.sh>

```bash
$ etcdctl get / --prefix --keys-only
$ etcdctl get / --prefix --keys-only | sed '/^$/d' | cut -d/ -f3 | sort | uniq -c | sort -rn
```

## Check performance

* KCS solutions/4885641
* <https://access.redhat.com/solutions/4770281>
* Command

~~~bash
$ oc rsh etcd-ip-10-0-130-137.us-east-2.compute.internal
Defaulting container name to etcdctl.
Use 'oc describe pod/etcd-ip-10-0-130-137.us-east-2.compute.internal -n openshift-etcd' to see all of the containers in this pod.
sh-4.4# etcdctl check perf [s][l]
PASS: Throughput is 150 writes/s
PASS: Slowest request took 0.319075s
PASS: Stddev is 0.011896s
PASS
~~~

## Check health

~~~bash
etcdctl member list
etcdctl endpoint health -w table
etcdctl endpint status -w table
~~~

## Recover etcd cluster

* Senario 1: only 1 etcd node is down

~~~bash
/etc/kubernetes/manifests/etcd-pod.yaml
/var/lib/etcd/*
Rsh to healthy etcd pod and remove the unhealthy member.
etcdctl member remove <member-id>
Force etcd redeployment. That’s it, we are done.
$ oc patch etcd cluster -p='{"spec": {"forceRedeploymentReason": "single-master-recovery-'"$( date --rfc-3339=ns )"'"}}' --type=merge


****** Redeploy the Kubescheduler

oc patch kubescheduler cluster -p='{"spec": {"forceRedeploymentReason": "recovery-'"$( date --rfc-3339=ns )"'"}}' --type=merge


~~~

* Senario 2: 2 of 3 nodes are down

~~~bash
To reproduce this scenario I just moved the /var/lib/etcd/member on two masters so that two etcd pods will go down and etcd cluster will be read only as quorum is lost. No oc commands will work here.
Interesting point to note here is that etcd on masters came up after some time. How ?
The master on which etcd container was working fine sent the database snapshot to etcd on other two masters.

2020-06-01 10:00:32.466772 I | rafthttp: database snapshot [index: 406027, to: f2e56ea5550173c2] sent out successfully
2020-06-01 10:00:48.796253 I | rafthttp: database snapshot [index: 406197, to: 737974dd43e6af7b] sent out successfully
Etcd container on the problematic master receives the database snapshot and saves it and then starts.
2020-06-01 10:00:32.068358 I | rafthttp: receiving database snapshot [index:406027, from f799aaf33af8e648] ...
2020-06-01 10:00:32.464175 I | snap: saved database snapshot to disk [total bytes: 78524416]
2020-06-01 10:00:32.464211 I | rafthttp: received and saved database snapshot [index: 406027, from: f799aaf33af8e648] successfully

I think this happens when quorum is lost in the etcd cluster.

If database snapshot is not sent by working etcd and cluster does not come back on its own then we need restore the etcd from snapshot.

~~~

* Senario 2-1: Restore from snapshot

~~~bash

Choose a master as recovery host and put the etcd backup in /home/core/

On other two masters, move /etc/kubernetes/manifests/etcd-pod.yaml and /var/lib/etcd/* to some backup location and confirm etcd container is not running.

Export NO_PROXY, HTTP_PROXY, and HTTPS_PROXY environment variables if cluster-wide proxy is enabled in the cluster.

On recovery master we need to run
 $ sudo -E /usr/local/bin/cluster-restore.sh /home/core/backup

This will start single member etcd.

Now we need to force etcd redeployment on masters so that full etcd cluster starts.
 $ oc patch etcd cluster -p='{"spec": {"forceRedeploymentReason": "recovery-'"$( date --rfc-3339=ns )"'"}}' --type=merge

Even if we do not force start etcd on masters, the single member etcd does send the snapshot file to other two master hosts, similar to 2 etcd pods down scenario.

Once etcd is updated with latest version, we need to force a new rollout of kubeapiserver, kubecontrollermanager and kubescheduler.

~~~

* Senario 3: Replace 1 master node

~~~bash

https://docs.openshift.com/container-platform/4.7/backup_and_restore/replacing-unhealthy-etcd-member.html#restore-replace-crashlooping-etcd-member_replacing-unhealthy-etcd-member

One of the masters is not working or running or is beyond repair.
Identify the unhealthy etcd member and delete it from etcd cluster.
For IPI installation:
Get machine object of unhealthy master from openshift-machine-api project and save its configuration i.e. machine yaml.
Edit the machine yaml and delete providerID, status section, then change the name of machine and update selfLink accordingly.
Delete machine of unhealthy etcd and apply new machine’s yaml which we edited. This will delete etcd pod of that machine.
Once the machine is created new revision of etcd is forced and etcd scales up automatically.

Identify the unhealthy etcd member and delete it from etcd cluster.
For UPI installation:
Delete the master node:
oc delete node <problematic master>
Recreate the master machine from ignition file which was used during the installation.
Update DNS and haproxy with correct entries for new master, if IP and hostnames are changed.
Approve CSRs for new master.
In case if api or controller or scheduler pod does not come up then we can force the redeploy it.

~~~

* Senario 4: Replace 2 masters

~~~bash
Here two masters are down or not running at all and we need to replace them.
Etcd cluster will be in read only mode and no oc commands will work.
Api and controller will also be down on the remaining master.
So igniting new master node/s will not work as it will be waiting for configuration from  MCO.
The only option here is to restore the snapshot on the only remaining master. This will bring single etcd cluster up on the remaining master.
For UPI installation, ignite new two masters.
For IPI, make use of machine objects and create two new machines for master nodes.
We must create two new machines first and then delete the old ones.
With this new revision is forced and etcd will scale up automatically on new masters.

~~~
