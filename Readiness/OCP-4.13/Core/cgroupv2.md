# Switch to Cgroup v2

```bash
$ oc edit nodes.config cluster

apiVersion: config.openshift.io/v1
kind: Node
metadata:
  name: cluster
  spec:
    cgroupMode: "v2"
```
