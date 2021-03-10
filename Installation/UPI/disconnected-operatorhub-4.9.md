# Disconnected Operatorhub

Internet <------> Workstation <------> Registry <------> OCP Cluster

## Set environment variables

~~~bash
$ export WORKSTATION_HOST=workstation.mycluster.nancyge.com
$ export WORKSTATION_IP=10.0.81.187
$ export REGISTRY_HOST=registry.mycluster.nancyge.com # It can be resolved by DNS
$ export NAMESPACE=olm-mirror
~~~

## Create Registry CA and Certificate

~~~bash
$ yum install -y podman httpd-tools

$ mkdir -p /opt/registry/{auth,certs,data}
$ mkdir -p /etc/crts/ && cd /etc/crts/

$ htpasswd -bBc /opt/registry/auth/htpasswd cchen redhat

$ openssl genrsa -out /etc/crts/cert.ca.key 4096

$ openssl req -x509 \
  -new -nodes \
  -key /etc/crts/cert.ca.key \
  -sha256 \
  -days 36500 \
  -out /etc/crts/cert.ca.crt \
  -subj /CN="Local Red Hat Ren Signer" \
  -reqexts SAN \
  -extensions SAN \
  -config <(cat /etc/pki/tls/openssl.cnf \
      <(printf '[SAN]\nbasicConstraints=critical, CA:TRUE\nkeyUsage=keyCertSign, cRLSign, digitalSignature'))

$ openssl genrsa -out /etc/crts/cert.key 2048

# $ openssl req -new -sha256 \
#     -key /etc/crts/cert.key \
#     -subj "/O=Local Cert/CN=$REGISTRY_HOST" \
#     -reqexts SAN \
#     -config <(cat /etc/pki/tls/openssl.cnf \
#         <(printf "\n[SAN]\nsubjectAltName=DNS:$REGISTRY_HOST\nbasicConstraints=critical, CA:FALSE\nkeyUsage=digitalSignature, keyEncipherment, keyAgreement, dataEncipherment\nextendedKeyUsage=serverAuth")) \
#     -out /etc/crts/cert.csr

# $ openssl x509 \
#     -req \
#     -sha256 \
#     -extfile <(printf "subjectAltName=DNS:$REGISTRY_HOST\nbasicConstraints=critical, CA:FALSE\nkeyUsage=digitalSignature, keyEncipherment, keyAgreement, dataEncipherment\nextendedKeyUsage=serverAuth") \
#     -days 3650 \
#     -in /etc/crts/cert.csr \
#     -CA /etc/crts/cert.ca.crt \
#     -CAkey /etc/crts/cert.ca.key \
#     -CAcreateserial -out /etc/crts/cert.crt

$ openssl req -new -sha256 \
    -key /etc/crts/cert.key \
    -subj "/O=Local Cert/CN=$REGISTRY_HOST" \
    -reqexts SAN \
    -config <(cat /etc/pki/tls/openssl.cnf \
        <(printf "\n[SAN]\nsubjectAltName=IP:$REGISTRY_HOST\nbasicConstraints=critical, CA:FALSE\nkeyUsage=digitalSignature, keyEncipherment, keyAgreement, dataEncipherment\nextendedKeyUsage=serverAuth")) \
    -out /etc/crts/cert.csr

$ openssl x509 \
    -req \
    -sha256 \
    -extfile <(printf "subjectAltName=IP:$REGISTRY_HOST\nbasicConstraints=critical, CA:FALSE\nkeyUsage=digitalSignature, keyEncipherment, keyAgreement, dataEncipherment\nextendedKeyUsage=serverAuth") \
    -days 3650 \
    -in /etc/crts/cert.csr \
    -CA /etc/crts/cert.ca.crt \
    -CAkey /etc/crts/cert.ca.key \
    -CAcreateserial -out /etc/crts/cert.crt

$ openssl x509 -in /etc/crts/cert.crt -text

$ cp /etc/crts/cert.key  /opt/registry/certs/$REGISTRY_HOST.key
$ cp /etc/crts/cert.crt  /opt/registry/certs/$REGISTRY_HOST.crt

$ cp /etc/crts/cert.ca.crt /etc/pki/ca-trust/source/anchors/

$ update-ca-trust extract
~~~

## Run the Registry container

~~~bash
$ podman run --name mirror-registry \
-p 5000:5000 \
-v /opt/registry/data:/var/lib/registry:z \
-v /opt/registry/auth:/auth:z \
-e "REGISTRY_AUTH=htpasswd" \
-e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
-e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
-v /opt/registry/certs:/certs:z \
-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/$REGISTRY_HOST.crt \
-e REGISTRY_HTTP_TLS_KEY=/certs/$REGISTRY_HOST.key \
-d docker.io/library/registry:2
~~~

## Trust the CA in your workstation

~~~bash
$ scp /etc/crts/cert.ca.crt $WORKSTATION_IP:/etc/pki/ca-trust/source/anchors/

<Do this in your Workstation>

$ update-ca-trust extract
$ podman login $REGISTRY_HOST:5000
~~~

## Disabling the default OperatorHub sources

~~~bash
$ oc patch OperatorHub cluster --type json \
    -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'
~~~

## Pruning an index image

~~~bash
$ podman login registry.redhat.io
$ podman login $REGISTRY_HOST:5000

## In order to get the whole operator list, we start redhat-operator-index
$ podman run -p50051:50051 \
    -it registry.redhat.io/redhat/redhat-operator-index:v4.6

<Open another terminal and gain the whole list>

$ grpcurl -plaintext localhost:50051 api.Registry/ListPackages > packages.out

$ opm index prune \
    -f registry.redhat.io/redhat/redhat-operator-index:v4.7 \
    -p advanced-cluster-management,jaeger-product,quay-operator,cluster-logging,elasticsearch-operator,serverless-operator \
    -t $REGISTRY_HOST:5000/$NAMESPACE/redhat-operator-index:v4.7

-f: index to prune
-p: the included operators
-t: Custom tag for new index image being built

## Then push the new index image to Registry
$ podman push $REGISTRY_HOST:5000/$NAMESPACE/redhat-operator-index:v4.7
~~~

## Mirroring an Operator catalog

~~~bash
Set environment variables
$ REG_CREDS=${XDG_RUNTIME_DIR}/containers/auth.json
~~~

~~~bash
Then run mirror command

$ podman login $REGISTRY_HOST:5000
$ oc adm catalog mirror \
    $REGISTRY_HOST:5000/$NAMESPACE/redhat-operator-index:v4.7 \
    $REGISTRY_HOST:5000/$NAMESPACE \
    -a ${REG_CREDS} \
    --insecure

<Sample output>

info: Mirroring completed in 34m59.01s (46.13MB/s)
no digest mapping available for 10.0.138.30:5000/olm-mirror/redhat-operator-index:v4.6, skip writing to ImageContentSourcePolicy
wrote mirroring manifests to manifests-redhat-operator-index-1622107696
~~~

## Trust extra CA

<https://docs.openshift.com/container-platform/4.7/cicd/builds/setting-up-trusted-ca.html>

~~~bash
$ oc create configmap registry-ca -n openshift-config --from-file=$REGISTRY_HOST..5000=/etc/pki/ca-trust/source/anchors/cert.ca.crt

$ oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"registry-ca"}}}' --type=merge
~~~

## Configure secrets

~~~bash
$ oc extract secret/pull-secret -n openshift-config --confirm

<Edit .dockerconfigjson file, append your credentials and rename it to new_dockerconfigjson>

$ oc set data secret/pull-secret -n openshift-config \
    --from-file=.dockerconfigjson=new_dockerconfigjson
~~~

## Create CatalogSource and ImageContentSourcePolicy

~~~bash
$ oc apply -f manifests-redhat-operator-index-1622107696/CatalogSource.yaml
$ oc apply -f manifests-redhat-operator-index-1622107696/ImageContentSourcePolicy.yaml
~~~

## Updating an index image

~~~bash
First locate the bundle image and SHA256 that you want to add

$ podman run -p 50051:50051 -it registry.redhat.io/redhat/redhat-operator-index:v4.7
$ grpcurl -plaintext localhost:50051 api.Registry.ListBundles > bundles.txt
$ egrep '"bundlePath|value"' bundles.txt | grep ocs -B2

In this case I want to add OCS operator

registry.redhat.io/ocs4/ocs-operator-bundle@sha256:70757ff902e868423ac3d46f7853d4931b8d0069357c68e1746f87643c67410f
~~~

~~~bash
$ opm index add -b registry.redhat.io/ocs4/ocs-operator-bundle@sha256:70757ff902e868423ac3d46f7853d4931b8d0069357c68e1746f87643c67410f -f registry.mycluster.nancyge.com:5000/olm-mirror/redhat-operator-index:v4.6 -t registry.mycluster.nancyge.com:5000/olm-mirror/redhat-operator-index:v4.7 -p podman

-b: the bundle that you want to add
-f: --from-index, the pruned index or the official index you previously used
-t: --tag, your registry+image+tag
-p: podman/docker, this is required; otherwise you'll get "error resolving" error bug#1836881
~~~
