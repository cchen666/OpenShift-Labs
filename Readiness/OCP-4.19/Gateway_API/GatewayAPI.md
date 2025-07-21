# Gateway API

<https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking/index#ingress-gateway-api>

## GatewayClass

```bash
oc apply -f files/GatewayClass.yaml
```

```bash
$ oc get deployment -n openshift-ingress
NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
istiod-openshift-gateway   1/1     1            1           2m35s
router-default             2/2     2            2           48m
```

## Create secret

```bash

$ cat cert.py
# Recommend to create python venv 3.10 first and install trustme package
import trustme
import datetime

# Create a CA

ca = trustme.CA()

# CA issues the certificate
expires=datetime.datetime(2035, 12, 1, 8, 10, 10)

server_cert = ca.issue_cert(u"*.gwapi.apps.hackathon-419-cchen.test.dev", not_after=expires)

# Save the CA cert

ca.cert_pem.write_to_path("ca.crt")

# Save server, client cert and key

server_cert.private_key_pem.write_to_path("server.key")
server_cert.cert_chain_pems[0].write_to_path("server.crt")

$ python3.12 cert.py

$ oc -n openshift-ingress create secret tls gwapi-wildcard --cert=server.crt --key=server.key
secret/gwapi-wildcard created

```

## Create Gateway

```bash

$ oc apply -f files/Gateway.yaml
gateway.gateway.networking.k8s.io/example-gateway created

$ oc get deployment -n openshift-ingress example-gateway-openshift-default
NAME                                READY   UP-TO-DATE   AVAILABLE   AGE
example-gateway-openshift-default   1/1     1            1           46s

$ oc get service -n openshift-ingress example-gateway-openshift-default
NAME                                TYPE           CLUSTER-IP     EXTERNAL-IP                                                               PORT(S)                         AGE
example-gateway-openshift-default   LoadBalancer   172.30.172.2   a8cb35ceb031343889be3a379eb33998-2110653735.us-east-2.elb.amazonaws.com   15021:30457/TCP,443:31761/TCP   65s

$ oc -n openshift-ingress get dnsrecord -l gateway.networking.k8s.io/gateway-name=example-gateway -o yaml
<Snip>
  status:
    observedGeneration: 1
    zones:
    - conditions:
      - lastTransitionTime: "2025-07-21T03:15:11Z"
        message: The DNS provider succeeded in ensuring the record
        reason: ProviderSuccess
        status: "True"
        type: Published
      dnsZone:
        tags:
          Name: hackathon-419-cchen-gqxt8-int
          kubernetes.io/cluster/hackathon-419-cchen-gqxt8: owned
    - conditions:
      - lastTransitionTime: "2025-07-21T03:15:12Z"
        message: The DNS provider succeeded in ensuring the record
        reason: ProviderSuccess
        status: "True"
        type: Published
      dnsZone:
        id: Z02462851UECNKMYID8II

```

## Create HTTPRoute and deploy workload

```bash

$ oc apply -f files/HTTPRoute.yaml
httproute.gateway.networking.k8s.io/example-route created

$ oc apply -f files/workload.yaml
namespace/example-app-ns created
deployment.apps/example-app-deployment created
service/example-app created

$ oc wait -n openshift-ingress --for=condition=Programmed gateways.gateway.networking.k8s.io example-gateway
gateway.gateway.networking.k8s.io/example-gateway condition met

```

## Test

```bash

$ curl  --cacert ca.crt https://example.gwapi.apps.hackathon-419-cchen.test.dev:443
Hello from your Red Hat image!

```
