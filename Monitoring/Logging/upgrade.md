# EFK Stack upgrade from 4.X to 5.0/5.1

<https://docs.openshift.com/container-platform/4.7/logging/cluster-logging-upgrading.html>

* Env: Disconnected OperatorHub
* From: 4.6
* To: 5.1

~~~bash
# oc project openshift-logging
Now using project "openshift-logging" on server "https://api.mycluster.nancyge.com:6443".
[root@ip-10-0-40-92 manifests-redhat-operator-index-1631010012]# oc get csv
NAME                                        DISPLAY                            VERSION              REPLACES                  PHASE
argocd-operator.v0.0.15                     Argo CD                            0.0.15               argocd-operator.v0.0.14   Succeeded
cert-utils-operator.v1.0.7                  Cert Utils Operator                1.0.7                                          Succeeded
clusterlogging.4.6.0-202106021513           Cluster Logging                    4.6.0-202106021513                             Succeeded
elasticsearch-operator.4.6.0-202106021513   OpenShift Elasticsearch Operator   4.6.0-202106021513                             Succeeded
~~~

## Optional: Update the OperatorHub if it is disconnected environment

~~~bash
# Specify related environments first
$ opm index prune     -f registry.redhat.io/redhat/redhat-operator-index:v4.8     -p cluster-logging,elasticsearch-operator     -t $REGISTRY_IP:5000/$NAMESPACE/redhat-operator-index:v4.8

$ podman push $REGISTRY_IP:5000/$NAMESPACE/redhat-operator-index:v4.8

$ oc adm catalog mirror     $REGISTRY_HOST:5000/$NAMESPACE/redhat-operator-index:v4.8     $REGISTRY_HOST:5000/$NAMESPACE     -a ${REG_CREDS}

$ oc apply -f catalogSource.yaml
$ oc apply -f imageContentSourcePolicy.yaml
~~~

## Update ElasticSearch Operator First to 5.1

 Navigate to console Operators -> Installed Operators -> ElasticSearch operator -> Edit Subscription Channel from 4.6 to 5.1 and operator will begin to upgrade automatically

~~~bash
# oc get csv
NAME                                DISPLAY                            VERSION              REPLACES                                    PHASE
argocd-operator.v0.0.15             Argo CD                            0.0.15               argocd-operator.v0.0.14                     Succeeded
cert-utils-operator.v1.0.7          Cert Utils Operator                1.0.7                                                            Succeeded
clusterlogging.4.6.0-202106021513   Cluster Logging                    4.6.0-202106021513                                               Succeeded
elasticsearch-operator.5.1.1-36     OpenShift Elasticsearch Operator   5.1.1-36             elasticsearch-operator.4.6.0-202106021513
~~~

## Update Cluster Logging Operator to 5.1: the same steps with ElasticSearch Operator

~~~bash
# oc get csv -n openshift-logging
NAME                                DISPLAY                            VERSION              REPLACES                                    PHASE
argocd-operator.v0.0.15             Argo CD                            0.0.15               argocd-operator.v0.0.14                     Succeeded
cert-utils-operator.v1.0.7          Cert Utils Operator                1.0.7                                                            Succeeded
cluster-logging.5.1.1-36            Red Hat OpenShift Logging          5.1.1-36             clusterlogging.4.6.0-202106021513           Installing
clusterlogging.4.6.0-202106021513   Cluster Logging                    4.6.0-202106021513                                               Replacing
elasticsearch-operator.5.1.1-36     OpenShift Elasticsearch Operator   5.1.1-36             elasticsearch-operator.4.6.0-202106021513   Succeeded


# oc get csv -n openshift-logging
NAME                              DISPLAY                            VERSION    REPLACES                                    PHASE
argocd-operator.v0.0.15           Argo CD                            0.0.15     argocd-operator.v0.0.14                     Succeeded
cert-utils-operator.v1.0.7        Cert Utils Operator                1.0.7                                                  Succeeded
cluster-logging.5.1.1-36          Red Hat OpenShift Logging          5.1.1-36   clusterlogging.4.6.0-202106021513           Succeeded
elasticsearch-operator.5.1.1-36   OpenShift Elasticsearch Operator   5.1.1-36   elasticsearch-operator.4.6.0-202106021513   Succeeded

# oc get pods
NAME                                            READY   STATUS      RESTARTS   AGE
cluster-logging-operator-54c6cc7d76-9khnf       1/1     Running     0          2m5s
elasticsearch-cdm-me8rg01g-1-6db44d6d6c-qwbkr   2/2     Running     0          4m47s
elasticsearch-cdm-me8rg01g-2-7f5c48d948-4m95h   2/2     Running     0          3m37s
elasticsearch-cdm-me8rg01g-3-7bf8649dbf-d5btw   2/2     Running     0          2m18s
elasticsearch-im-app-27183510-nb4wx             0/1     Completed   0          12m
elasticsearch-im-audit-27183510-jcg6f           0/1     Completed   0          12m
elasticsearch-im-infra-27183510-nfc2n           0/1     Completed   0          12m
fluentd-5hnzp                                   1/1     Running     0          29s
fluentd-bjssk                                   0/1     Init:0/1    0          7s
fluentd-cjd6q                                   1/1     Running     6          75d
fluentd-gz7rm                                   1/1     Running     0          89s
fluentd-pcmpf                                   1/1     Running     4          77d
fluentd-wdxfk                                   1/1     Running     0          69s
kibana-bd46c7c9-bjpxj                           2/2     Running     0          4m51s

# oc get pods
NAME                                            READY   STATUS      RESTARTS   AGE
cluster-logging-operator-54c6cc7d76-9khnf       1/1     Running     0          9m23s
elasticsearch-cdm-me8rg01g-1-6db44d6d6c-qwbkr   2/2     Running     0          12m
elasticsearch-cdm-me8rg01g-2-7f5c48d948-4m95h   2/2     Running     0          10m
elasticsearch-cdm-me8rg01g-3-7bf8649dbf-d5btw   2/2     Running     0          9m36s
elasticsearch-im-app-27183525-qx2tk             0/1     Completed   0          4m26s
elasticsearch-im-audit-27183525-xpnqr           0/1     Completed   0          4m26s
elasticsearch-im-infra-27183525-k4rzj           0/1     Completed   0          4m26s
fluentd-5hnzp                                   1/1     Running     0          7m47s
fluentd-7pznl                                   1/1     Running     0          6m54s
fluentd-bjssk                                   1/1     Running     0          7m25s
fluentd-gz7rm                                   1/1     Running     0          8m47s
fluentd-nghjp                                   1/1     Running     0          6m33s
fluentd-wdxfk                                   1/1     Running     0          8m27s
kibana-bd46c7c9-bjpxj                           2/2     Running     0          12m
~~~
