# Health Probe Configuration Override

## Get the current nmstate

```bash

$ oc get nmstate -n openshift-nmstate -o yaml
apiVersion: nmstate.io/v1
kind: NMState
metadata:
  creationTimestamp: "2025-07-23T01:50:07Z"
  generation: 1
  name: nmstate
  resourceVersion: "884406"
  uid: 1ec85950-72cc-481d-86f0-f90871bde24b
spec:
  probeConfiguration:
    dns:
      host: root-servers.net
```

## Edit the probeConfiguration

```bash

$ oc edit nmstate nmstate -n openshift-nmstate
<Snip>
spec:
  probeConfiguration:
    dns:
      host: redhat.com

```

## Confirm the nmstate-handler Pod is restarted

```bash

$ oc get pod -n openshift-nmstate
NAME                                      READY   STATUS    RESTARTS   AGE
nmstate-console-plugin-5f6b754795-cc4zn   1/1     Running   0          4m25s
nmstate-handler-857pz                     1/1     Running   0          8s
nmstate-handler-9rcpm                     1/1     Running   0          22s
nmstate-handler-cr2vq                     1/1     Running   0          29s
nmstate-handler-jdm86                     1/1     Running   0          36s
nmstate-handler-zbdk4                     1/1     Running   0          15s
nmstate-metrics-6c9b49f455-hssmm          2/2     Running   0          4m26s
nmstate-operator-d79bb9f65-k8mgz          1/1     Running   0          15m
nmstate-webhook-84455475dd-j4db4          1/1     Running   0          4m26s
nmstate-webhook-84455475dd-tp28q          1/1     Running   0          4m26s

```

## Test1

```bash

$ oc apply -f files/nncp.yaml
nodenetworkconfigurationpolicy.nmstate.io/set-dns-worker created

$ oc get nncp -n openshift-nmstate
NAME                                                       STATUS      STATUS AGE   REASON
ip-10-0-17-136.us-east-2.compute.internal.set-dns-worker   Available   38s          SuccessfullyConfigured
ip-10-0-38-165.us-east-2.compute.internal.set-dns-worker   Available   43s          SuccessfullyConfigured

$ oc logs -n openshift-nmstate nmstate-handler-857pz

{"level":"info","ts":"2025-07-23T01:59:02.506Z","logger":"probe","msg":"Running 'ping' probe"}
{"level":"info","ts":"2025-07-23T01:59:02.717Z","logger":"probe","msg":"Running 'dns' probe"}
{"level":"info","ts":"2025-07-23T01:59:02.971Z","logger":"probe","msg":"Running 'api-server' probe"}
{"level":"info","ts":"2025-07-23T01:59:02.976Z","logger":"probe","msg":"Running 'node-readiness' probe"}

```

## Test2

```bash

$ oc delete -f files/nncp.yaml
nodenetworkconfigurationpolicy.nmstate.io "set-dns-worker" deleted

$ oc get nncp -n openshift-nmstate
No resources found in openshift-nmstate namespace.

$ oc edit nmstate nmstate -n openshift-nmstate
<Snip>
spec:
  probeConfiguration:
    dns:
      host: invaliddomain.abcdef

$ oc apply -f files/nncp.yaml
nodenetworkconfigurationpolicy.nmstate.io/set-dns-worker created

$ oc get nnce -n openshift-nmstate
NAME                                                       STATUS        STATUS AGE   REASON
ip-10-0-17-136.us-east-2.compute.internal.set-dns-worker   Pending       2s           MaxUnavailableLimitReached
ip-10-0-38-165.us-east-2.compute.internal.set-dns-worker   Progressing   36s          ConfigurationProgressing

$ oc logs -n openshift-nmstate nmstate-handler-mpzsn

{"level":"error","ts":"2025-07-23T02:07:39.992Z","logger":"probe","msg":"failed checking DNS connectivity","error":"[lookup invaliddomain.abcdef on 8.8.8.8:53: no such host]","stacktrace":"github.com/nmstate/kubernetes-nmstate/pkg/probe.runDNS\n\t/go/src/github.com/openshift/kubernetes-nmstate/pkg/probe/probes.go:265\ngithub.com/nmstate/kubernetes-nmstate/pkg/probe.dnsCondition.func1\n\t/go/src/github.com/openshift/kubernetes-nmstate/pkg/probe/probes.go:219\nk8s.io/apimachinery/pkg/util/wait.loopConditionUntilContext.func2\n\t/go/src/github.com/openshift/kubernetes-nmstate/vendor/k8s.io/apimachinery/pkg/util/wait/loop.go:87\nk8s.io/apimachinery/pkg/util/wait.loopConditionUntilContext\n\t/go/src/github.com/openshift/kubernetes-nmstate/vendor/k8s.io/apimachinery/pkg/util/wait/loop.go:88\nk8s.io/apimachinery/pkg/util/wait.PollUntilContextTimeout\n\t/go/src/github.com/openshift/kubernetes-nmstate/vendor/k8s.io/apimachinery/pkg/util/wait/poll.go:48\ngithub.com/nmstate/kubernetes-nmstate/pkg/probe.Select\n\t/go/src/github.com/openshift/kubernetes-nmstate/pkg/probe/probes.go:287\ngithub.com/nmstate/kubernetes-nmstate/pkg/client.ApplyDesiredState\n\t/go/src/github.com/openshift/kubernetes-nmstate/pkg/client/client.go:159\ngithub.com/nmstate/kubernetes-nmstate/controllers/handler.(*NodeNetworkConfigurationPolicyReconciler).Reconcile\n\t/go/src/github.com/openshift/kubernetes-nmstate/controllers/handler/nodenetworkconfigurationpolicy_controller.go:226\nsigs.k8s.io/controller-runtime/pkg/internal/controller.(*Controller[...]).Reconcile\n\t/go/src/github.com/openshift/kubernetes-nmstate/vendor/sigs.k8s.io/controller-runtime/pkg/internal/controller/controller.go:116\nsigs.k8s.io/controller-runtime/pkg/internal/controller.(*Controller[...]).reconcileHandler\n\t/go/src/github.com/openshift/kubernetes-nmstate/vendor/sigs.k8s.io/controller-runtime/pkg/internal/controller/controller.go:303\nsigs.k8s.io/controller-runtime/pkg/internal/controller.(*Controller[...]).processNextWorkItem\n\t/go/src/github.com/openshift/kubernetes-nmstate/vendor/sigs.k8s.io/controller-runtime/pkg/internal/controller/controller.go:263\nsigs.k8s.io/controller-runtime/pkg/internal/controller.(*Controller[...]).Start.func2.2\n\t/go/src/github.com/openshift/kubernetes-nmstate/vendor/sigs.k8s.io/controller-runtime/pkg/internal/controller/controller.go:224"}

$ oc edit nmstate nmstate -n openshift-nmstate
<Snip>
spec:
  probeConfiguration:
    dns:
      host: redhat.com

$ oc get nnce -n openshift-nmstate
NAME                                                       STATUS      STATUS AGE   REASON
ip-10-0-17-136.us-east-2.compute.internal.set-dns-worker   Available   3s           SuccessfullyConfigured
ip-10-0-38-165.us-east-2.compute.internal.set-dns-worker   Available   2m9s         SuccessfullyConfigured

```
