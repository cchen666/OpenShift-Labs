# ElasticSearch Cluster on Kubernetes

## Deploy the Operator

In Command Line:

~~~bash

$ oc create -f https://download.elastic.co/downloads/eck/2.1.0/crds.yaml
$ oc apply -f https://download.elastic.co/downloads/eck/2.1.0/operator.yaml

~~~

## Deploy ElasticSearch CR

~~~bash

$ oc new-project test-es
$ oc apply -f files/elasticsearch/ECK_es.yaml
$ oc apply -f files/elasticsearch/ECK_kibana.yaml

~~~

## Get elastic Password

~~~bash

$ PASSWORD=$(oc get secret elasticsearch-sample-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
$ echo $PASSWORD

~~~

## Use Trusted Certificate for Kibana

By default Kibana uses its own CA to sign the certificate. So you have to trust the self-signed CA when login to the Kibana. Here we change the self-signed certificate to the cert which is signed by publicly trusted CA.

~~~bash

# Examine the files/elasticsearch/ECK_kibana_tls.yaml and replace the certificate and key with your publicly facing certificate and key

$ oc apply -f files/elasticsearch/ECK_kibana_tls.yaml

~~~

## Validation

~~~bash

$  oc get route
NAME                   HOST/PORT                                                 PATH   SERVICES                       PORT    TERMINATION            WILDCARD
elasticsearch-sample   elasticsearch-sample-test-es.apps.mycluster.nancyge.com          elasticsearch-sample-es-http   <all>   passthrough/Redirect   None
kibana-sample          kibana-sample-test-es.apps.mycluster.nancyge.com                 kibana-sample-kb-http          <all>   passthrough/Redirect   None

$ curl -k -u elastic:$PASSWORD https://elasticsearch-sample-test-es.apps.mycluster.nancyge.com/_cat/nodes?v
ip           heap.percent ram.percent cpu load_1m load_5m load_15m node.role   master name
10.131.0.241           20          73   8    1.88    2.28     2.48 cdfhilmrstw -      elasticsearch-sample-es-default-1
10.128.2.44            50          73   3    3.05    8.07     7.62 cdfhilmrstw *      elasticsearch-sample-es-default-2
10.128.2.45            53          71   7    3.05    8.07     7.62 cdfhilmrstw -      elasticsearch-sample-es-default-0

~~~
