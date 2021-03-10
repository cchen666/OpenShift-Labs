# Code Analyze

<https://github1s.com/openshift/cluster-dns-operator/blob/release-4.8/pkg/operator/controller/controller.go#L88-L89>

## go-callvis

~~~bash

$ go-callvis -group type -focus github.com/openshift/cluster-dns-operator/pkg/operator/controller -limit github.com/openshift/cluster-dns-operator/pkg/operator/controller cmd/dns-operator/main.go

~~~

## reconciler struct

reconciler is a struct with only 3 items but 9 receivers. A receiver is a method inside the struct and the
struct instance could call the method directly.

~~~go

type reconciler struct {
    operatorconfig.Config

    client client.Client
    cache  cache.Cache
}

func (r *reconciler) Reconcile(ctx context.Context, request reconcile.Request) (reconcile.Result, error) {
func (r *reconciler) ensureExternalNameForOpenshiftService() error
func (r *reconciler) ensureOpenshiftExternalNameServiceDeleted()
func (r *reconciler) enforceDNSFinalizer(dns *operatorv1.DNS) error
func (r *reconciler) ensureDNSDeleted(dns *operatorv1.DNS) error
func (r *reconciler) ensureDNSNamespace() error
func (r *reconciler) ensureMetricsIntegration(dns *operatorv1.DNS, svc *corev1.Service, daemonsetRef metav1.OwnerReference) error
func (r *reconciler) ensureDNS(dns *operatorv1.DNS) error
func (r *reconciler) getClusterIPFromNetworkConfig() (string, error)

~~~

## Locate Reconcile() function

We only focus on Reconcile() function now.

~~~bash

Reconcile() line 88
  -> ensureDNSNamepace() line 115
    ->  ensureDNSClusterRole() line 245 def: controller_cluster_role.go line 18
      -> currentDNSClusterRole() line 42 controller_cluster_role.go
      # Search the desired ClusterRole CR, if currentDNSClusterRole is nil then create one
      r.client.Create(context.TODO(), desired) # desired = assets/dns/cluster-role.yaml


r.ensureDNSNamespace()
r.enforceDNSFinalizer(dns)
r.ensureDNS(dns)
r.ensureExternalNameForOpenshiftService()

~~~
