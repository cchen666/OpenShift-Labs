# Machine AutoScaler

## Supported on AWS, GCP, Azure, OSP, Vsphere

```bash
apiVersion: "autoscaling.openshift.io/v1beta1"
kind: "MachineAutoscaler"
metadata:
  name: "worker-gpu"
  namespace: "openshift-machine-api"
spec:
  minReplicas: 0
  maxReplicas: 10
  scaleTargetRef:
    apiVersion: machine.openshift.io/v1beta1
    kind: MachineSet
    name: my-machine-set
```
