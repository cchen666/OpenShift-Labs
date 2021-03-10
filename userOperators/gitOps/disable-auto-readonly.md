# Disable Auto View of ArgoCD

<https://cloud.redhat.com/blog/a-guide-to-using-gitops-and-argocd-with-rbac>

By default the ArgoCD CR will allow any users to have read-only permission. This means any user could view every application by default. To disable this:

```bash

$ oc edit argocd <Your ArgoCD CR Name>
spec:
  rbac:
    defaultPolicy: role:none
    policy: |
      p, role:none, applications, get, */*, deny
      p, role:none, certificates, get, *, deny
      p, role:none, clusters, get, *, deny
      p, role:none, repositories, get, *, deny
      p, role:none, projects, get, *, deny
      p, role:none, accounts, get, *, deny
      p, role:none, gpgkeys, get, *, deny
      g, system:cluster-admins, role:admin
      g, cluster-admins, role:admin
      g, argocdusers, role:readonly
    scopes: '[groups]'
```

The above rbac policy defines the defaultPolicy needs to use role:none. It simply removes all the permissions from  the role:none. It grants the permission to group `cluster-admins` with `admin` role, and `argocdusers` with `readonly` role.
