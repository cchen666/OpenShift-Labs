#### Election/Heartbeat Flow
http://thesecretlivesofdata.com/
#### Official learning material
https://github.com/etcd-io/etcd/tree/release-3.4/Documentation/learning
https://github.com/etcd-io/etcd/tree/release-3.4/Documentation/faq.md
#### Get all the keys
~~~
# etcdctl get / --prefix --keys-only
~~~
#### Check performance
* KCS solutions/4885641
* Command
~~~
$ oc rsh etcd-ip-10-0-130-137.us-east-2.compute.internal
Defaulting container name to etcdctl.
Use 'oc describe pod/etcd-ip-10-0-130-137.us-east-2.compute.internal -n openshift-etcd' to see all of the containers in this pod.
sh-4.4# etcdctl check perf [s][l]
PASS: Throughput is 150 writes/s
PASS: Slowest request took 0.319075s
PASS: Stddev is 0.011896s
PASS
~~~
