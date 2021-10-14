# ArgoCD GitOps

## Install GitOps Operator in OperatorHub

By doing this you'll get an out-of-box ArgoCD instance under openshift-gitops namespace.

~~~bash
$ oc get pods -n openshift-gitops
cluster-d469b8c87-kxh8l                                       1/1     Running   0          4h52m
kam-7f748468cd-7t62z                                          1/1     Running   0          5h33m
openshift-gitops-application-controller-0                     1/1     Running   0          4h51m
openshift-gitops-applicationset-controller-66db7bd58c-qpd42   1/1     Running   0          4h52m
openshift-gitops-dex-server-d7c777869-pt2cf                   1/1     Running   0          4h52m
openshift-gitops-redis-7867d74fb4-dw5st                       1/1     Running   0          5h33m
openshift-gitops-repo-server-64f767c4b6-728wk                 1/1     Running   0          4h52m
openshift-gitops-server-5964dbdd56-j7vkm                      1/1     Running   0          4h52m
~~~

## Configure ArgoCD Service Account Permission

### Option 1

~~~bash

# We open cluster-admin permission to ArgoCD Service Account.

$ cat << EOF > clusterrolebinding.yaml

kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: openshift-gitops-cluster-admin
subjects:
  - kind: ServiceAccount
    name: openshift-gitops-argocd-application-controller
    namespace: openshift-gitops
  - kind: ServiceAccount
    name: openshift-gitops-applicationset-controller
    namespace: openshift-gitops
  - kind: ServiceAccount
    name: openshift-gitops-argocd-server
    namespace: openshift-gitops
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin

EOF

$ oc apply -f clusterrolebinding.yaml
~~~

### Option 2

~~~bash
# Add precise permission to ArgoCD Service Account.

# From the result of creating cert-manager Application, we know that the following 3 errors will be output.

customresourcedefinitions.apiextensions.k8s.io is forbidden: User "system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller" cannot create resource "customresourcedefinitions" in API group "apiextensions.k8s.io" at the cluster scope

mutatingwebhookconfigurations.admissionregistration.k8s.io is forbidden: User "system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller" cannot create resource "mutatingwebhookconfigurations" in API group "admissionregistration.k8s.io" at the cluster scope

validatingwebhookconfigurations.admissionregistration.k8s.io is forbidden: User "system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller" cannot create resource "validatingwebhookconfigurations" in API group "admissionregistration.k8s.io" at the cluster scope

# So we need to grant the above resources permission to argocd SA.
# We dump its Role and modify it

$ oc get clusterrole openshift-gitops-openshift-gitops-argocd-application-controller -o yaml > /tmp/files/role.yaml

$ cat role.yaml
<Snip>
name: cchen-test-gitops-role
<Snip>

- apiGroups:
  - admissionregistration.k8s.io
  resources:
  - mutatingwebhookconfigurations
  verbs:
  - '*'
- apiGroups:
  - admissionregistration.k8s.io
  resources:
  - validatingwebhookconfigurations
  verbs:
  - '*'
- apiGroups:
  - apiextensions.k8s.io
  resources:
  - customresourcedefinitions
  verbs:
  - '*'

$ oc apply -f role.yaml
clusterrole.rbac.authorization.k8s.io/cchen-test-gitops-role created

# Specify the newly created role and assign it to ArgoCD SA.

$ cat rolebinding.yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: openshift-gitops-cluster-admin
subjects:
  - kind: ServiceAccount
    name: openshift-gitops-argocd-application-controller
    namespace: openshift-gitops
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cchen-test-gitops-role

$ oc apply -f rolebinding.yaml
clusterrolebinding.rbac.authorization.k8s.io/openshift-gitops-cluster-admin created
~~~

## Label cert-manager namespace

~~~bash
$ oc edit namespace/cert-manager
  labels:
    argocd.argoproj.io/managed-by: openshift-gitops
~~~

## Create Application by using default ArgoCD instance

~~~bash
$ cat << EOF > app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cert-manager
  namespace: openshift-gitops
spec:
  destination:
    namespace: cert-manager
    server: https://kubernetes.default.svc
  project: default
  source:
    path: app
    repoURL: https://github.com/cchen666/gitops
  syncPolicy:
    automated:
      prune: true
      selfHeal: true

EOF

$ oc apply -f app.yaml

# In https://github.com/cchen666/gitops we got app/kustomization.yaml and inside it we have:

apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml

# So when the Application is created, ArgoCD will run app/kustomization.yaml; As a result cert-manager
# will be created in this example.
~~~

## Access ArgoCD UI

~~~bash
# Get ArgoCD URL

$ oc get route -n openshift-gitops
openshift-gitops-server   openshift-gitops-server-openshift-gitops.apps.mycluster.nancyge.com          openshift-gitops-server   https   passthrough/Redirect   None

# Get admin user password

$ oc extract secret/openshift-gitops-cluster -n openshift-gitops --confirm
admin.password

$ cat admin.password
2GD37LItiwKElcX4ZUx1uRvTjVJBrfdO
~~~

## Good Sample

<https://github.com/ocpdude/ocp-argocd>