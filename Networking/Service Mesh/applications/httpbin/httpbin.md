# httpbin with TLS

<https://github.com/maistra/maistra-test-tool/blob/maistra-2.3/testdata/examples/x86/httpbin/httpbin.yaml>

## Create Project, assign SCC, deployment and service

~~~bash

$ oc new-project httpbin
$ oc adm policy add-scc-to-user privileged -z default -n httpbin

$ oc edit smmr -n istio-system # Add httpbin to the members

$ oc apply -f files/httpbin.yaml -n httpbin

$ oc get pods # You should see 2/2 which means sidecar has been injected
NAME                      READY   STATUS    RESTARTS   AGE
httpbin-d59d7f86c-jp4wf   2/2     Running   0          9m40s
~~~

## Create TLS secret

~~~bash

$ oc -n openshift-ingress extract secret/router-certs-default --to=- --keys=tls.crt > /tmp/tls.crt
$ oc -n openshift-ingress extract secret/router-certs-default --to=- --keys=tls.key > /tmp/tls.key
$ oc create -n istio-system secret tls httpbin-credential --key=/tmp/tls.key --cert=/tmp/tls.crt # The key is wildcard certificate for *.apps.mycluster.nancyge.com
# For dumping CARoot of Ingress, use: $ oc extract secret/router-ca -n openshift-ingress-operator --to=- --keys=tls.crt

~~~

## Create Gateway and VirtualService

~~~bash

$ oc apply -f files/httpbin-gateway.yaml -n httpbin
$ oc apply -f files/httpbin-virtualService.yaml -n httpbin

$ oc get route -n istio-system
NAME                                 HOST/PORT                                                      PATH   SERVICES               PORT    TERMINATION          WILDCARD
grafana                              grafana-istio-system.apps.mycluster.nancyge.com                       grafana                <all>   reencrypt/Redirect   None
httpbin-mygateway-52594eff2b877cde   httpbin.apps.mycluster.nancyge.com                                    istio-ingressgateway   https   passthrough          None
istio-ingressgateway                 istio-ingressgateway-istio-system.apps.mycluster.nancyge.com          istio-ingressgateway   8080    edge                 None
jaeger                               jaeger-istio-system.apps.mycluster.nancyge.com                        jaeger-query           <all>   reencrypt            None
kiali                                kiali-istio-system.apps.mycluster.nancyge.com                         kiali                  20001   reencrypt/Redirect   None
prometheus                           prometheus-istio-system.apps.mycluster.nancyge.com                    prometheus             <all>   reencrypt/Redirect   None

~~~

## Test

~~~bash

$ curl -k https://httpbin.apps.mycluster.nancyge.com/status/418

    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`

$ oc logs -f istio-ingressgateway-b45c9d54d-2pqzc -n istio-system # We don't see Client IP here

[2022-01-27T14:41:36.124Z] "GET /status/418 HTTP/2" 418 - via_upstream - "-" 0 135 5 4 "10.128.2.35" "curl/7.64.1" "c876d2f9-52ab-9bad-a7f5-383d5a5ecc48" "httpbin.apps.mycluster.nancyge.com" "10.128.2.113:80" outbound|8000||httpbin.httpbin.svc.cluster.local 10.128.2.200:49520 10.128.2.200:8443 10.128.2.35:41704 httpbin.apps.mycluster.nancyge.com -

$ oc get svc -n httpbin
NAME      TYPE           CLUSTER-IP       EXTERNAL-IP                                                               PORT(S)          AGE
httpbin   LoadBalancer   172.30.186.117   a9502e31858924042b3ef99c23cc3025-1256110993.us-east-2.elb.amazonaws.com   8000:30018/TCP   12h

$ aws elb describe-load-balancer-policies --load-balancer-name a9502e31858924042b3ef99c23cc3025 --policy-names k8s-proxyprotocol-enabled # AWS ELB has already enabled Proxy Protocol
{
    "PolicyDescriptions": [
        {
            "PolicyName": "k8s-proxyprotocol-enabled",
            "PolicyTypeName": "ProxyProtocolPolicyType",
            "PolicyAttributeDescriptions": [
                {
                    "AttributeName": "ProxyProtocol",
                    "AttributeValue": "true"
                }
            ]
        }
    ]
}

# According to https://istio.io/latest/docs/tasks/security/authorization/authz-ingress/, we need enable proxy protocol in istio level as well. But after applying EnvoyFilter the page can not be accessed.

~~~
