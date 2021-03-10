# Access Metrics without Using Prometheus

## Check Who Signs the Cert for Port 10250

~~~bash

$ echo Q | openssl s_client -connect 10.72.36.88:10250 | openssl x509 -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            6b:c7:fc:c7:7c:74:19:10:a2:7b:41:7b:33:91:02:d9
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = kube-csr-signer_@1662182755

~~~

## Get Kubelet Root CA

~~~bash

$ oc get cm kubelet-serving-ca -o yaml -n openshift-config-managed # Save the ca-bundle.crt to /tmp

~~~

## Create metrics-viewer ClusterRole

~~~bash

$ oc get clusterrole | grep prometheus
prometheus-adapter                                                                      2022-09-02T10:40:39Z
prometheus-k8s                                                                          2022-09-02T10:43:07Z
prometheus-k8s-scheduler-resources                                                      2022-09-02T10:15:23Z
prometheus-operator                                                                     2022-09-02T10:40:15Z

$ oc get clusterrole prometheus-k8s -o yaml

$ oc apply -f files/metrics-viewer.yaml

~~~

## Create metrics-viewer SA

~~~bash

$ oc project default
$ oc create sa metrics-viewer
$ oc adm policy add-cluster-role-to-user metrics-viewer -z metrics-viewer

# Get SA's token

$ oc get sa metrics-viewer -o yaml
apiVersion: v1
imagePullSecrets:
- name: metrics-viewer-dockercfg-vk4mg
kind: ServiceAccount
metadata:
  creationTimestamp: "2022-09-15T02:55:34Z"
  name: metrics-viewer
  namespace: default
  resourceVersion: "37282701"
  uid: 291e009e-e08a-4cba-9119-a336759e9808
secrets:
- name: metrics-viewer-dockercfg-vk4mg
- name: metrics-viewer-token-dqfmw # <========

$ oc extract secret/metrics-viewer-token-dqfmw --keys=token  --to=/tmp --confirm

~~~

## Curl the Metrics

~~~bash

$ curl  --cacert /tmp/ca-bundle.crt -H "Authorization: Bearer $(cat /tmp/token) " https://10.72.36.88:10250/metrics | wc -l
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  350k    0  350k    0     0  12.6M      0 --:--:-- --:--:-- --:--:-- 12.6M
2513

~~~
