# Node

## Node info

oc adm top node <node>
oc describe node <node> | grep taint

oc whoami --show-console

## Recreate /etc/kubenetes/manifests
~~~
oc patch etcd cluster -p='{"spec": {"forceRedeploymentReason": "recovery-'"$( date --rfc-3339=ns )"'"}}' --type=merge
oc patch kubecontrollermanager cluster -p='{"spec": {"forceRedeploymentReason": "recovery-'"$( date --rfc-3339=ns )"'"}}' --type=merge
oc patch kubescheduler cluster -p='{"spec": {"forceRedeploymentReason": "recovery-'"$( date --rfc-3339=ns )"'"}}' --type=merge
~~~

## Create POD outside the OCP cluster

~~~bash
$ podman run -v $(pwd)/:/kubeconfig -e KUBECONFIG=/kubeconfig/kubeconfig -e LATENCY_TEST_RUN=true -e DICOVERY_MODE=true -e LATENCY_TEST_CPUS=7 -e LATENCY_TEST_RUNTIME=600 -e MAXIMUM_LATENCY=20 -e ROLE_WORKER_CNF=master
-e CLEAN_PERFORMANCE_PROFILE=false
 registry.redhat.io/openshift4/cnf-tests-rhel8:v4.9 /usr/bin/test-run.sh -ginkgo.focus="oslat"

 crictl pull <image>
 podman pull <image> --authfile /var/lib/kubelet/config.json
 $ oc get pods -n performance-addon-operator-testing

perf stat -a -A --smi-cost 
podman run --privileged -it -v /:/host --rm --entrypoint bash quay.io/alosadag/troubleshoot:latest

https://github.com/SchSeba/dpdk-testpm-trex-example/blob/main/pods/dpdk/trex/testpmd.yaml#L62

~~~