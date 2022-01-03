#### Check the Parameters
~~~
$ oc describe pod prometheus-k8s-0
prometheus:
  Container ID:  cri-o://45cd22ff8b8ed3925881386bc987b6712c87986fcdb98d1c231bfbb43602f8bb
  Image:         quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:4292e3aac0c4439f99b0174707d7d5c5af3b727707a6b15640f1e24270a8e49e
  Image ID:      quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:4292e3aac0c4439f99b0174707d7d5c5af3b727707a6b15640f1e24270a8e49e
  Port:          <none>
  Host Port:     <none>
  Args:
    --web.console.templates=/etc/prometheus/consoles
    --web.console.libraries=/etc/prometheus/console_libraries
    --config.file=/etc/prometheus/config_out/prometheus.env.yaml
    --storage.tsdb.path=/prometheus
    --storage.tsdb.retention.time=15d
    --web.enable-lifecycle
    --storage.tsdb.no-lockfile
    --web.external-url=https://prometheus-k8s-openshift-monitoring.apps.mycluster.ocp.com/
    --web.route-prefix=/
    --web.listen-address=127.0.0.1:9090



~~~

~~~
$ egrep '^[a-z]|^\-' /etc/prometheus/config_out/prometheus.env.yaml

global:
rule_files:
- /etc/prometheus/rules/prometheus-k8s-rulefiles-0/*.yaml
scrape_configs:
- job_name: serviceMonitor/openshift-apiserver-operator/openshift-apiserver-operator/0
- job_name: serviceMonitor/openshift-apiserver/openshift-apiserver/0
- job_name: serviceMonitor/openshift-apiserver/openshift-apiserver-operator-check-endpoints/0
- job_name: serviceMonitor/openshift-authentication-operator/authentication-operator/0
- job_name: serviceMonitor/openshift-authentication/oauth-openshift/0
- job_name: serviceMonitor/openshift-cloud-credential-operator/cloud-credential-operator/0
- job_name: serviceMonitor/openshift-cluster-machine-approver/cluster-machine-approver/0
- job_name: serviceMonitor/openshift-cluster-node-tuning-operator/node-tuning-operator/0
- job_name: serviceMonitor/openshift-cluster-samples-operator/cluster-samples-operator/0
- job_name: serviceMonitor/openshift-cluster-storage-operator/cluster-storage-operator/0
- job_name: serviceMonitor/openshift-cluster-version/cluster-version-operator/0
- job_name: serviceMonitor/openshift-cnv/kubevirt-hyperconverged-operator-metrics/0
- job_name: serviceMonitor/openshift-config-operator/config-operator/0
- job_name: serviceMonitor/openshift-console-operator/console-operator/0
- job_name: serviceMonitor/openshift-controller-manager-operator/openshift-controller-manager-operator/0
- job_name: serviceMonitor/openshift-controller-manager/openshift-controller-manager/0
- job_name: serviceMonitor/openshift-dns-operator/dns-operator/0
- job_name: serviceMonitor/openshift-dns/dns-default/0
- job_name: serviceMonitor/openshift-etcd-operator/etcd-operator/0
- job_name: serviceMonitor/openshift-image-registry/image-registry/0
- job_name: serviceMonitor/openshift-image-registry/image-registry-operator/0
- job_name: serviceMonitor/openshift-ingress-operator/ingress-operator/0
- job_name: serviceMonitor/openshift-ingress/router-default/0
- job_name: serviceMonitor/openshift-insights/insights-operator/0
- job_name: serviceMonitor/openshift-kube-apiserver-operator/kube-apiserver-operator/0
- job_name: serviceMonitor/openshift-kube-apiserver/kube-apiserver/0
- job_name: serviceMonitor/openshift-kube-controller-manager-operator/kube-controller-manager-operator/0
- job_name: serviceMonitor/openshift-kube-controller-manager/kube-controller-manager/0
- job_name: serviceMonitor/openshift-kube-scheduler-operator/kube-scheduler-operator/0
- job_name: serviceMonitor/openshift-kube-scheduler/kube-scheduler/0
- job_name: serviceMonitor/openshift-kube-scheduler/kube-scheduler/1
- job_name: serviceMonitor/openshift-machine-api/cluster-autoscaler-operator/0
- job_name: serviceMonitor/openshift-machine-api/machine-api-controllers/0
- job_name: serviceMonitor/openshift-machine-api/machine-api-controllers/1
- job_name: serviceMonitor/openshift-machine-api/machine-api-controllers/2
- job_name: serviceMonitor/openshift-machine-api/machine-api-operator/0
- job_name: serviceMonitor/openshift-machine-config-operator/machine-config-daemon/0
- job_name: serviceMonitor/openshift-marketplace/marketplace-operator/0
- job_name: serviceMonitor/openshift-monitoring/alertmanager/0
- job_name: serviceMonitor/openshift-monitoring/cluster-monitoring-operator/0
- job_name: serviceMonitor/openshift-monitoring/etcd/0
- job_name: serviceMonitor/openshift-monitoring/grafana/0
- job_name: serviceMonitor/openshift-monitoring/kube-state-metrics/0
- job_name: serviceMonitor/openshift-monitoring/kube-state-metrics/1
- job_name: serviceMonitor/openshift-monitoring/kubelet/0
- job_name: serviceMonitor/openshift-monitoring/kubelet/1
- job_name: serviceMonitor/openshift-monitoring/kubelet/2
- job_name: serviceMonitor/openshift-monitoring/kubelet/3
- job_name: serviceMonitor/openshift-monitoring/node-exporter/0
- job_name: serviceMonitor/openshift-monitoring/openshift-state-metrics/0
- job_name: serviceMonitor/openshift-monitoring/openshift-state-metrics/1
- job_name: serviceMonitor/openshift-monitoring/prometheus-adapter/0
- job_name: serviceMonitor/openshift-monitoring/prometheus-k8s/0
- job_name: serviceMonitor/openshift-monitoring/prometheus-kubevirt-rules/0
- job_name: serviceMonitor/openshift-monitoring/prometheus-operator/0
- job_name: serviceMonitor/openshift-monitoring/telemeter-client/0
- job_name: serviceMonitor/openshift-monitoring/thanos-querier/0
- job_name: serviceMonitor/openshift-monitoring/thanos-sidecar/0
- job_name: serviceMonitor/openshift-multus/monitor-multus-admission-controller/0
- job_name: serviceMonitor/openshift-multus/monitor-network/0
- job_name: serviceMonitor/openshift-oauth-apiserver/openshift-oauth-apiserver/0
- job_name: serviceMonitor/openshift-operator-lifecycle-manager/catalog-operator/0
- job_name: serviceMonitor/openshift-operator-lifecycle-manager/olm-operator/0
- job_name: serviceMonitor/openshift-sdn/monitor-sdn/0
- job_name: serviceMonitor/openshift-service-ca-operator/service-ca-operator/0
alerting:
~~~
