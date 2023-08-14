# Known Issues

## Role Binding

* The default out of box ArgoCD instance doesn't have enough permissions to create resources in other namespace

## Dex will not be enabled by default after upgrading from 1.x to 1.3

<https://abhishekveeramalla-av.medium.com/configuring-sso-for-openshift-gitops-v1-3-26e5f0f02214>

## Foreground propagation policy is not working for particular resources

By default GitOps uses `foreground` propagation policy to delete resources. However some resources can not be deleted in foreground propagation due to [this](https://github.com/openshift/kubernetes/blob/60f5a1c6c03d74665057a4ad0f25383404605bef/cmd/kube-controller-manager/app/patch_gc.go#L16)

Workaround is to add following options

```bash

  syncPolicy:
    syncOptions:
    - PrunePropagationPolicy=background

```
