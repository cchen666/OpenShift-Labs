# API

## To check which resources are provided by which apiserver

Local means it is provided by k8s or CRD while openshift-apiserver/api means it is provided by openshift

~~~bash
$ oc get apiservices.apiregistration.k8s.io
NAME                                     SERVICE                                                      AVAILABLE   AGE
v1.                                      Local                                                        True        7d21h
v1.admissionregistration.k8s.io          Local                                                        True        7d21h
v1.apiextensions.k8s.io                  Local                                                        True        7d21h
v1.apps                                  Local                                                        True        7d21h
v1.apps.openshift.io                     openshift-apiserver/api                                      True        7d21h
v1.authentication.k8s.io                 Local                                                        True        7d21h

~~~

## To check all the resources

~~~ bash
$ oc api-resources
~~~

## List all the CRDs

~~~ bash
$ oc get customresourcedefinitions.apiextensions.k8s.io
~~~

## To trace the API call

~~~bash
$ oc get pods --loglevel=6
I0507 10:28:45.539055   13155 loader.go:375] Config loaded from file:  /Users/cchen/kubeconfig
I0507 10:28:46.547746   13155 round_trippers.go:443] GET https://api.mycluster.nancyge.com:6443/api/v1/namespaces/openshift-kube-controller-manager/pods?limit=500 200 OK in 999 milliseconds
NAME                                                                 READY   STATUS      RESTARTS   AGE
installer-2-ip-10-0-187-180.us-east-2.compute.internal               0/1     Completed   0          7d21h
installer-3-ip-10-0-130-137.us-east-2.compute.internal               0/1     Completed   0          7d21h
installer-4-ip-10-0-199-90.us-east-2.compute.internal                0/1     Completed   0          7d21h
installer-5-ip-10-0-130-137.us-east-2.compute.internal               0/1     Completed   0          7d21h

~~~

## To list api versions

~~~bash
$ oc api-versions
admissionregistration.k8s.io/v1
admissionregistration.k8s.io/v1beta1
apiextensions.k8s.io/v1
apiextensions.k8s.io/v1beta1
apiregistration.k8s.io/v1
apiregistration.k8s.io/v1beta1
apps.openshift.io/v1
apps/v1
authentication.k8s.io/v1

<Snip of oc get project --loglevel=6>

I0507 11:39:14.711590   13268 round_trippers.go:443] GET https://api.mycluster.nancyge.com:6443/apis/authorization.k8s.io/v1?timeout=32s 200 OK in 1177 milliseconds
I0507 11:39:14.711605   13268 round_trippers.go:443] GET https://api.mycluster.nancyge.com:6443/apis/coordination.k8s.io/v1beta1?timeout=32s 200 OK in 1177 milliseconds
I0507 11:39:14.711611   13268 round_trippers.go:443] GET https://api.mycluster.nancyge.com:6443/apis/admissionregistration.k8s.io/v1beta1?timeout=32s 200 OK in 1177 milliseconds
~~~

## Test API legacy

~~~bash
$ curl -k https://api.<OCP URL>.com -w "%{time_connect},%{time_total},%{speed_download},%{http_code},%{size_download},%{url_effective}\n"
$  curl -k https://api.master.paas.ubrmb.com.com -w "%{time_connect},%{time_total},%{speed_download},%{http_code},%{size_download},%{url_effective}\n"
0.617,3.714,0.000,302,0,https://api.master.paas.ubrmb.com.com/
~~~
