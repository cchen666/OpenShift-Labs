# Network

## Bypass the LB

```bash

# curl -k https://<route> --resolve <route>:443:<IP of worker node>
# curl -k https://<route> --resolve <route>:443:<IP of worker node> -vIL

$ ROUTE=$(oc get route -n openshift-ingress-canary -ojsonpath={..host}) ;\
$ ROUTER=$(oc get pod -n openshift-ingress -o wide | grep -v NAME | grep Running | grep router-default | awk {'print $6'} | head -n 1) ;\
$ curl -k -v --noproxy '*' --resolve ${ROUTE}:443:${ROUTER} https://${ROUTE}

# Or

$ curl -k https://canary-openshift-ingress-canary.apps.gcg-shift.cchen.work --resolve canary-openshift-ingress-canary.apps.gcg-shift.cchen.work:443:10.72.48.25

```
