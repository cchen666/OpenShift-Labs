# Live Migration from SDN to OVN

1. To start the migration, configure the OVN-Kubernetes network plugin by using one of the following commands:

```bash
$ oc patch Network.config.openshift.io cluster --type='merge' --patch '{"metadata":{"annotations":{"network.openshift.io/network-type-migration":""}},"spec":{"networkType":"OVNKubernetes"}}'
```
