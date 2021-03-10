# What Logs to be Collected

## MTV

```bash
# MTV
$ oc get csv -A | grep -i mtv
$ oc adm must-gather --image=registry.redhat.io/migration-toolkit-virtualization/mtv-must-gather-rhel8:<mtv-operator-version>

```

## Must-Gather

```bash
$ oc adm must-gather  --image=registry.redhat.io/container-native-virtualization/cnv-must-gather-rhel8:v4.12.0

```
