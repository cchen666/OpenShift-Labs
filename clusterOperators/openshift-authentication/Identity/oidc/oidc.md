# Integrate OpenShift Authentication with Keycloak (RHSSO)

## Install RHSSO Operator

## Dump the Ingress CA and Create ConfigMap Based on it

```bash
$ oc get secret -n openshift-ingress-operator router-ca -o yaml | less

$ oc create configmap idpdemo-oidc-client-ca-cert --from-file=ca.crt=/tmp/ingress-ca.crt -n openshift-config
```

## Get admin Password

```bash

$ oc get secret credential-example-keycloak -o yaml

```

## Edit Oauth Cluster CR

<https://console-openshift-console.apps.cchen414.cchen.work/k8s/cluster/config.openshift.io~v1~OAuth/cluster?idpAdded=true>

```bash

```