# Create Local User in ArgoCD Instance

<https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/#local-usersaccounts-v15>

## Get Admin Password

~~~bash
$ cat `oc extract secret/openshift-gitops-cluster -n openshift-gitops --confirm`
DthEKVHxdJGnlMXXXXXXX
~~~

## Install argocd CLI on a Linux Client

~~~bash

$ export ARGO_VERSION="v2.12.13"
$ curl -sLO https://github.com/argoproj/argo-workflows/releases/download/${ARGO_VERSION}/argo-linux-amd64.gz
$ gunzip argo-linux-amd64.gz
$ cp argocd-linux-amd64 /usr/local/bin/argocd
$ chmod +x /usr/local/bin/argocd

~~~

## Add User by Editing argocd-cm CM

* argocd-cm is controlled by the operator but `data.accounts` is not. However we don't recommend using local user but DEX SSO integrated

    ~~~bash

    $ oc edit cm argocd-cm -n openshift-gitops
    data:
    accounts.john: apiKey,login  // <===== Add this line

    $ argocd account list
    NAME   ENABLED  CAPABILITIES
    admin  true     login
    ~~~

## Create Password for User

~~~bash
$ argocd account update-password --account john
*** Enter current password: DthEKVHxdJGnlXXXXXXXX (admin password)
*** Enter new password:
*** Confirm new password:
Password updated
~~~

* Confirm john can login <https://openshift-gitops-server-openshift-gitops.apps.mycluster.XXXXXX.com/>
