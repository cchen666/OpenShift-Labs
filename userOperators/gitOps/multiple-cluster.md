# ArgoCD to Manage Multiple Cluster

<https://www.youtube.com/watch?v=Lx2hd_lbhxY>

## Get the Admin Password from Secret

~~~bash

$ oc get secret -n openshift-gitops openshift-gitops-cluster -o yaml

~~~

## Login ArgoCD CLI

~~~bash

$ brew install argocd

$ argocd login openshift-gitops-server-openshift-gitops.apps.gcg-shift.cchen.work
Username: admin
Password:
'admin:login' logged in successfully

~~~

## Add Cluster

1. Login to your external Cluster and Confirm the current context

    ~~~bash

    $ oc login https://api.sno-pek.cchen.work:6443  -u kubeadmin
    $ oc config get-contexts
    CURRENT   NAME                                                                            CLUSTER                          AUTHINFO                                      NAMESPACE
            /api-cchen-titamu-com:6443/cchen                                                api-cchen-titamu-com:6443        cchen/api-cchen-titamu-com:6443
            /api-cchen-titamu-com:6443/yhuang                                               api-cchen-titamu-com:6443        yhuang/api-cchen-titamu-com:6443
            admin                                                                           mycluster                        admin
            default/api-cchen-titamu-com:6443/kube:admin                                    api-cchen-titamu-com:6443        kube:admin/api-cchen-titamu-com:6443          default
            default/api-gcg-shift-cchen-work:6443/kube:admin                                api-gcg-shift-cchen-work:6443    kube:admin/api-gcg-shift-cchen-work:6443      default
            default/api-mycluster-nancyge-com:6443/system:admin                             api-mycluster-nancyge-com:6443   system:admin/api-mycluster-nancyge-com:6443   default
    *         default/api-sno-pek-cchen-work:6443/kube:admin                                  api-sno-pek-cchen-work:6443      kube:admin/api-sno-pek-cchen-work:6443        default
    ~~~

2. Add Cluster by using ArgoCD CLI

    ~~~bash

    $ argocd cluster add default/api-sno-pek-cchen-work:6443/kube:admin

    ~~~

## Create ApplicationSet

~~~bash

$ oc apply files/applicationSet.yaml

~~~
