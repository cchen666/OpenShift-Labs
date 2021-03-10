# Configure OAuth Identity Provider

## Add Gitlab Repositories in ArgoCD UI

<https://argo-cd.readthedocs.io/en/release-2.0/user-guide/private-repositories/#self-signed-untrusted-tls-certificates>

1. Use git@gitlab.cee.redhat.com:cchen/gitops.git
2. Check Skip Server Verification
3. Upload your ssh key

## Grant Permissions to ServiceAccount

```bash

$ oc apply -f files/clusterRole-secret.yaml
$ oc apply -f files/clusterRoleBinding.yaml

```

## Edit ArgoCD CR

<https://github.com/argoproj/argo-cd/issues/5792>

```bash

$ oc edit argocd -n openshift-gitops
spec:
  resourceIgnoreDifferences:
    all:
      jsonPointers:
      - /data
      - /metadata
      managedFieldsManagers:
      - authentication-operator
```

## Create Application

```bash

$ oc apply -f files/application-oauth.yaml

```
