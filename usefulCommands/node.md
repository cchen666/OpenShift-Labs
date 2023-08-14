# Node

## Node info

```bash
oc adm top node <node>
oc describe node <node> | grep taint

oc whoami --show-console
```

## Recreate /etc/kubenetes/manifests

```bash
oc patch etcd cluster -p='{"spec": {"forceRedeploymentReason": "recovery-'"$( date --rfc-3339=ns )"'"}}' --type=merge
oc patch kubecontrollermanager cluster -p='{"spec": {"forceRedeploymentReason": "recovery-'"$( date --rfc-3339=ns )"'"}}' --type=merge
oc patch kubescheduler cluster -p='{"spec": {"forceRedeploymentReason": "recovery-'"$( date --rfc-3339=ns )"'"}}' --type=merge
oc patch kubeapiserver cluster -p='{"spec": {"forceRedeploymentReason": "recovery-'"$( date --rfc-3339=ns )"'"}}' --type=merge
```

## Create POD outside the OCP cluster

```bash
$ podman run -v $(pwd)/:/kubeconfig -e KUBECONFIG=/kubeconfig/kubeconfig -e LATENCY_TEST_RUN=true -e DICOVERY_MODE=true -e LATENCY_TEST_CPUS=7 -e LATENCY_TEST_RUNTIME=600 -e MAXIMUM_LATENCY=20 -e ROLE_WORKER_CNF=master
-e CLEAN_PERFORMANCE_PROFILE=false
 registry.redhat.io/openshift4/cnf-tests-rhel8:v4.9 /usr/bin/test-run.sh -ginkgo.focus="oslat"

 crictl pull <image>
 podman pull <image> --authfile /var/lib/kubelet/config.json
 $ oc get pods -n performance-addon-operator-testing

perf stat -a -A --smi-cost
podman run --privileged -it -v /:/host --rm --entrypoint bash quay.io/alosadag/troubleshoot:latest

https://github.com/SchSeba/dpdk-testpm-trex-example/blob/main/pods/dpdk/trex/testpmd.yaml#L62

```

## Label the node and set NodeSelector

```bash
$ oc label nodes worker03.ocp4.example.com env=nginx
$ oc patch deployment/nginx  --patch '{"spec":{"template":{"spec":{"nodeSelector":{"env":"nginx"}}}}}'
```

## Some Json tricks

```bash

$ oc get deployment console -o jsonpath='{.spec.template.spec.containers[0].image}'
$ oc patch smcp/basic -p='{"spec":{"general":{"logging":{"componentLevels":{"ior":"debug"}}}}}'  --type=merge
$ oc patch smcp basic --type json -p '[{"op": "remove", "path": "/spec/general/logging/componentLevels/ior"}]'
# openshift list all pods and thier specs (requests/limits)
$ oc get pod -o jsonpath='{range .items[*]}{"SPEC:  \n  LIMITS  : "}{.spec.containers[*].resources.limits}{"\n  REQUESTS: "}{.spec.containers[*].resources.requests}{"\n"}{end}'
# openshift list all pods and thier specs with name (requests /limits)
$ oc get pod -o jsonpath='{range .items[*]}{"NAME:  "}{.metadata.name}{"\nSPEC:  \n  LIMITS  : "}{.spec.containers[*].resources.limits}{"\n  REQUESTS: "}{.spec.containers[*].resources.requests}{"\n\n"}{end}'
# openshift list all nodes and thier corresponding os/kernel verion
$ oc get nodes -o jsonpath='{range .items[*]}{"\t"}{.metadata.name}{"\t"}{.status.nodeInfo.osImage}{"\t"}{.status.nodeInfo.kernelVersion}{"\n"}{end}'
# openshift patch build config with patch
$ oc patch bc/kube-ops-view -p '{"spec":{"resources":{"limits":{"cpu":"1","memory":"1024Mi"},"requests":{"cpu":"100m","memory":"256Mi"}}}}'
# openshift display the images used by Replication Controller
$ oc get rc -n openshift-infra -o jsonpath='{range .items[*]}{"RC: "}{.metadata.name}{"\n Image:"}{.spec.template.spec.containers[*].image}{"\n"}{end}'
# openshift display the requestor for namespace
$ oc get namespace ui-test -o template --template '{{ index .metadata.annotations "openshift.io/requester"  }}'
# openshift display all projects and its creator sorted by creator
$ IFS=,; while read data1 data2; do printf "%-60s : %-50s\n" $data1 $data2;
done < <( oc get projects -o template \
--template '{{range .items}}{{.metadata.name}},{{index .metadata.annotations "openshift.io/requester"}}{{"\n"}}{{end }}' |
sort -t, -k2 )
# openshift fetch custom column name from metadata
$ oc get rolebinding -o=custom-columns=USERS:.userNames,GROUPS:.groupNames


for i in `oc get pv  -o=custom-columns=NAME:.metadata.name | grep pvc` ;
   do oc describe pv $i | grep Path |awk '{print $2}';
done
```

## Regenerate IGN files

```bash

$ oc extract -n openshift-machine-api secret/master-user-data --keys=userData --to=-
$ oc extract -n openshift-machine-api secret/worker-user-data --keys=userData --to=-

```

## Check Namespaces Bound to Container

<https://www.nginx.com/blog/what-are-namespaces-cgroups-how-do-they-work/>

```bash

# List all the namespaces which the process 3063686 is using

$ lsns  -p 3063686
        NS TYPE   NPROCS     PID USER       COMMAND
4026531835 cgroup    197       1 root       /usr/lib/systemd/systemd --switched-root --system --deserialize 16
4026531837 user      197       1 root       /usr/lib/systemd/systemd --switched-root --system --deserialize 16
4026532502 uts         1 3063686 1000860000 sleep 3600
4026532503 ipc         1 3063686 1000860000 sleep 3600
4026532505 net         1 3063686 1000860000 sleep 3600
4026533367 mnt         1 3063686 1000860000 sleep 3600
4026533368 pid         1 3063686 1000860000 sleep 3600

# Seems we have to specify -m and -p at the same time so that we get correct PID tree because
# mnt namespace will mount proc to /proc while the ps command will read information under /proc
# thus we need mnt namespace together with pid namespace

$ nsenter -t 3063686 -m -p ps -ef
UID          PID    PPID  C STIME TTY          TIME CMD
root           1       0  0 13:51 ?        00:00:00 sleep 3600
root          25       0  0 14:05 ?        00:00:00 ps -ef

$ nsenter -t 3063686 -n ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
3: eth0@if41: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default
    link/ether 0a:58:0a:80:02:1f brd ff:ff:ff:ff:ff:ff link-netns 503ed3bc-029c-4454-942c-4c57992e9811
    inet 10.128.2.31/23 brd 10.128.3.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::c87a:5bff:fec3:f26f/64 scope link
       valid_lft forever preferred_lft forever

# Unknown question: why mount needs mnt and pid namespace to make it work ? Maybe because /proc
# both needs mnt and pid namespace at the same time?

$ nsenter -t 3063686 -m -p mount

```

## Check Node Log

```bash

$ oc adm node-logs worker01.ocp4.example.com -u kubelet

```

## Flash the CoreOS with Particular Image

```bash

$ mkdir -p /run/mco-machine-os-content/os-content-temp/

解压4.10.25的machine-os-content镜像文件：
$ oc image extract --insecure --path /:/run/mco-machine-os-content/os-content-temp --registry-config /var/lib/kubelet/config.json registry.redhat.io/ocp4/openshift4.10.25:4.10.25-x86_64-machine-os-content

找到对应的repo的commit：
$ find /run/mco-machine-os-content/os-content-temp/srv/repo/ -name '*.commit'
/run/mco-machine-os-content/os-content-temp/srv/repo/objects/51/69526cb197b3b26779ee31a7b77070b489e8624ed63f329518a86eac7f3e20.commit

填写commit和mc-rendered的osImageURL的url，执行rpm-ostree rebase升级ostree操作系统版本：
$ rpm-ostree rebase --experimental /run/mco-machine-os-content/os-content-temp/srv/repo:5169526cb197b3b26779ee31a7b77070b489e8624ed63f329518a86eac7f3e20 --custom-origin-url pivot://quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:375e222c564e23086be556668cde1f2139237479218b928c40c8e060ad1c6f25 --custom-origin-description 'Managed by machine-config-operator'

重启操作系统：
$ systemctl reboot

mc-daemon仍然报expect旧osImageURL的错误，由于/etc/machine-config-daemon/下残留旧的mc-daemon的历史数据会导致误报，需要手工清理一下。

$ rm -rf /etc/machine-config-daemon/*

```

## Force to Use osImageURL

```bash

# OCP 4.11

$ /run/bin/machine-config-daemon pivot quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:5dd050b18575c595f94d21e4d598fab6fc8a3251272973386b894c3ff1a26b20

# OCP 4.12 and later

$ rpm-ostree rebase --experimental ostree-unverified-registry:quay.io/openshift-release-dev/"Image"

```