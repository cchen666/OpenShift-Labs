# Locality with outlier detection
- label node **topology.kubernetes.io/zone**
```bash

```
- deploy app
```bash
oc apply -f ocp/backend-v1-deployment-with-node-selector.yml -n $USERID
oc apply -f ocp/backend-v2-deployment-with-node-selector.yml -n $USERID
oc apply -f ocp/frontend-v1-deployment-with-node-selector.yml -n $USERID
```
- check pod placement
```bash
oc get pods -o wide -n $USERID
```
- Test
```bash
scripts/loop
```
- Apply policy with outlier detection
```bash
oc apply -f istio_files/
```
