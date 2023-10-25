# Network

## Bypass the LB

```bash

# curl -k https://<route> --resolve <route>:443:<IP of worker node>
# curl -k https://<route> --resolve <route>:443:<IP of worker node> -vIL

$ curl -k https://canary-openshift-ingress-canary.apps.gcg-shift.cchen.work --resolve canary-openshift-ingress-canary.apps.gcg-shift.cchen.work:443:10.72.48.25

```
