# ArgoCD Additional Instance

## Create Namespaces

```bash

$ cat << EOF > namespace.yaml

---

apiVersion: v1
kind: Namespace
metadata:
  name: bar
spec:
  labels:
    argocd.argoproj.io/managed-by: foo # ArgoCD instance namespace
  finalizers:
  - kubernetes

---

apiVersion: v1
kind: Namespace
metadata:
  name: foo
spec:
  finalizers:
  - kubernetes

EOF

$ oc apply -f namespace.yaml
```

## Create ArgoCD Instance

```bash
# We can also use additional ArgoCD instance instead of the default out-of-box one

$ cat << EOF > argo-instance.yaml

apiVersion: argoproj.io/v1alpha1
kind: ArgoCD
metadata:
 name: argocd #name of the Argo CD instance
 namespace: foo # namespace where you want to deploy argocd instance
spec:
 server:
   route:
     enabled: true # creates an openshift route to access Argo CD UI
```

## Create Application

```bash

$ cat << EOF > argo-app.yaml

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sample-app-2
  namespace: foo # namespace where Argo CD instance is installed
spec:
  destination:
    namespace: bar # target namespace where app is deployed
    server: 'https://kubernetes.default.svc'
  source:
    path: app
    repoURL: 'https://github.com/redhat-developer/openshift-gitops-getting-started'
    targetRevision: HEAD
  project: default

EOF

$ oc apply -f argo-app.yaml
```

## More Information

<https://developers.redhat.com/articles/2021/08/03/managing-gitops-control-planes-secure-gitops-practices>
