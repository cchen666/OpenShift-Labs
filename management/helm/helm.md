# Helm

## Installation

~~~bash
$ brew install helm
~~~

## Helm Helloworld

~~~bash
$ cd /tmp
$ helm create mychart
$ ls -lR mychart
total 16
-rw-r--r--   1 cchen  wheel  1143 Apr 27 22:38 Chart.yaml
drwxr-xr-x   2 cchen  wheel    64 Apr 27 22:38 charts
drwxr-xr-x  10 cchen  wheel   320 Apr 27 22:38 templates
-rw-r--r--   1 cchen  wheel  1874 Apr 27 22:38 values.yaml

mychart/charts:

mychart/templates:
total 56
-rw-r--r--  1 cchen  wheel  1747 Apr 27 22:38 NOTES.txt
-rw-r--r--  1 cchen  wheel  1782 Apr 27 22:38 _helpers.tpl
-rw-r--r--  1 cchen  wheel  1836 Apr 27 22:38 deployment.yaml
-rw-r--r--  1 cchen  wheel   916 Apr 27 22:38 hpa.yaml
-rw-r--r--  1 cchen  wheel  2079 Apr 27 22:38 ingress.yaml
-rw-r--r--  1 cchen  wheel   361 Apr 27 22:38 service.yaml
-rw-r--r--  1 cchen  wheel   320 Apr 27 22:38 serviceaccount.yaml
drwxr-xr-x  3 cchen  wheel    96 Apr 27 22:38 tests

mychart/templates/tests:
total 8
-rw-r--r--  1 cchen  wheel  379 Apr 27 22:38 test-connection.yaml
~~~

## Create Helloworld Application

~~~bash
$ helm install test-mychart ./mychart
$ helm list
NAME          NAMESPACE REVISION UPDATED                              STATUS   CHART          APP VERSION
clunky-serval default   1        2022-04-27 21:42:59.812526 +0800 CST deployed mycharts-0.1.0 1.16.0
test-mychart  default   1        2022-04-27 22:39:24.368863 +0800 CST deployed mychart-0.1.0  1.16.0

$ oc get pods
NAME                                      READY   STATUS    RESTARTS   AGE
clunky-serval-mycharts-69d77fd6fb-ntkl7   1/1     Running   0          56m
test-mychart-db9f49b65-tt48t              1/1     Running   0          18s

$ oc get svc
NAME                     TYPE           CLUSTER-IP      EXTERNAL-IP                            PORT(S)   AGE
clunky-serval-mycharts   ClusterIP      172.30.23.19    <none>                                 80/TCP    58m
kubernetes               ClusterIP      172.30.0.1      <none>                                 443/TCP   20d
openshift                ExternalName   <none>          kubernetes.default.svc.cluster.local   <none>    20d
test-mychart             ClusterIP      172.30.155.25   <none>                                 80/TCP    101s

$ oc expose svc/test-mychart

$ curl test-mychart-default.apps.mycluster.nancyge.com
<Snip>
<title>Welcome to nginx!</title>
<Snip>
~~~

## Get Manifest

~~~bash
$ helm get manifest test-mychart
---
# Source: mychart/templates/serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: test-mychart
  labels:
    helm.sh/chart: mychart-0.1.0
    app.kubernetes.io/name: mychart
    app.kubernetes.io/instance: test-mychart
    app.kubernetes.io/version: "1.16.0"
    app.kubernetes.io/managed-by: Helm
---
# Source: mychart/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: test-mychart
  labels:
    helm.sh/chart: mychart-0.1.0
    app.kubernetes.io/name: mychart
    app.kubernetes.io/instance: test-mychart
    app.kubernetes.io/version: "1.16.0"
    app.kubernetes.io/managed-by: Helm
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app.kubernetes.io/name: mychart
    app.kubernetes.io/instance: test-mychart
---
# Source: mychart/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-mychart
  labels:
    helm.sh/chart: mychart-0.1.0
    app.kubernetes.io/name: mychart
    app.kubernetes.io/instance: test-mychart
    app.kubernetes.io/version: "1.16.0"
    app.kubernetes.io/managed-by: Helm
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: mychart
      app.kubernetes.io/instance: test-mychart
  template:
    metadata:
      labels:
        app.kubernetes.io/name: mychart
        app.kubernetes.io/instance: test-mychart
    spec:
      serviceAccountName: test-mychart
      securityContext:
        {}
      containers:
        - name: mychart
          securityContext:
            {}
          image: "nginx:1.16.0"
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /
              port: http
          readinessProbe:
            httpGet:
              path: /
              port: http
          resources:
            {}

~~~
