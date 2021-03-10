#### 1. How we can get the console and the password of kubeadmin after installation
* To get the console
~~~
$ oc get console.config.openshift.io cluster -o yaml
apiVersion: config.openshift.io/v1
kind: Console
metadata:
  annotations:
    release.openshift.io/create-only: "true"
  creationTimestamp: "2021-02-08T08:36:48Z"
  generation: 1
  managedFields:
  - apiVersion: config.openshift.io/v1
    fieldsType: FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          .: {}
          f:release.openshift.io/create-only: {}
      f:spec: {}
    manager: cluster-version-operator
    operation: Update
    time: "2021-02-08T08:36:48Z"
  - apiVersion: config.openshift.io/v1
    fieldsType: FieldsV1
    fieldsV1:
      f:spec:
        f:authentication: {}
      f:status:
        .: {}
        f:consoleURL: {}
    manager: console
    operation: Update
    time: "2021-02-08T08:49:46Z"
  name: cluster
  resourceVersion: "18062"
  selfLink: /apis/config.openshift.io/v1/consoles/cluster
  uid: f7c352d5-a4d2-4721-846d-0f7cb4a46e58
spec: {}
status:
  consoleURL: https://console-openshift-console.apps.mycluster.xxx.com
~~~
* To get the password
You need to login to the installer and check `kubeadmin-password` file.
