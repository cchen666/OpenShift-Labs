# ETCD Mutual TLS

## Client to Server

~~~bash
export HAPROXY_IP=10.74.251.171
$ oc debug node/master01.ocp4.example.net
sh-4.4# scp /etc/kubernetes/static-pod-certs/secrets/etcd-all-certs/etcd-peer-master01.ocp4.example.net.crt root@$HAPROXY_IP:/tmp
sh-4.4# scp /etc/kubernetes/static-pod-certs/configmaps/etcd-serving-ca/ca-bundle.crt root@$HAPROXY_IP:/tmp
sh-4.4# scp /etc/kubernetes/static-pod-certs/secrets/etcd-all-certs/etcd-peer-master01.ocp4.example.net.key root@$HAPROXY_IP:/tmp

# Download etcdctl from https://github.com/etcd-io/etcd/releases

$ systemctl restart haproxy

$ ./etcdctl  --endpoints=$HAPROXY_IP:2379 --insecure-skip-tls-verify=true --cert=/tmp/etcd-peer-master01.ocp4.example.net.crt --key=/tmp/etcd-peer-master01.ocp4.example.net.key member list
~~~
