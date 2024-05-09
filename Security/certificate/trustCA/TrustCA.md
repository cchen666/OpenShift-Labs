# Trust CA in OpenShift

## 1. additionalTrustedCA in image.config

* Create test ca file

```bash
$ openssl genpkey -algorithm RSA -out ca.key

$ openssl req -new -x509 -days 365 -key ca.key -out ca.crt

You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) []:CN
State or Province Name (full name) []:Liaoning
Locality Name (eg, city) []:Dalian
Organization Name (eg, company) []:RH
Organizational Unit Name (eg, section) []:GSS
Common Name (eg, fully qualified host name) []:test.cchen.work
Email Address []:XXXXXX@redhat.com

$ openssl x509 -in ca.crt -text

Certificate:
    Data:
        Version: 1 (0x0)
        Serial Number: 11300350194197806284 (0x9cd2e8a13aad3ccc)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=CN, ST=Liaoning, L=Dalian, O=RH, OU=GSS, CN=test.cchen.work/emailAddress=cchen@redhat.com
        Validity
            Not Before: Jun  2 02:51:23 2023 GMT
            Not After : Jun  1 02:51:23 2024 GMT
        Subject: C=CN, ST=Liaoning, L=Dalian, O=RH, OU=GSS, CN=test.cchen.work/emailAddress=cchen@redhat.com
        Subject Public Key Info:
```

* Create configMap and add it to image.config

```bash

$ oc create configmap registry-ca -n openshift-config --from-file=test.cchen.work..5000=/tmp/ca/ca.crt
configmap/registry-ca created

oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"registry-ca"}}}' --type=merge
image.config.openshift.io/cluster patched
```

* Verification

1. Check where the test.cchen.work..5000 will be created inside the node. Login to one of the nodes

    ```bash
    $

    $ find / 2>/dev/null | grep test.cchen

    # Pods will use this CA

    /sysroot/ostree/deploy/rhcos/var/lib/kubelet/pods/ee73918a-c16c-48be-9dfd-ba0d4577badf/volumes/kubernetes.io~configmap/serviceca/..2023_06_02_02_53_07.3903481854/test.cchen.work..5000
    /sysroot/ostree/deploy/rhcos/var/lib/kubelet/pods/ee73918a-c16c-48be-9dfd-ba0d4577badf/volumes/kubernetes.io~configmap/serviceca/test.cchen.work..5000
    /sysroot/ostree/deploy/rhcos/var/lib/kubelet/pods/86894834-929d-4a24-8889-2c37a27194a0/volumes/kubernetes.io~configmap/registry-certificates/..2023_06_02_02_53_55.962570959/test.cchen.work..5000
    /sysroot/ostree/deploy/rhcos/var/lib/kubelet/pods/86894834-929d-4a24-8889-2c37a27194a0/volumes/kubernetes.io~configmap/registry-certificates/test.cchen.work..5000
    /var/lib/kubelet/pods/ee73918a-c16c-48be-9dfd-ba0d4577badf/volumes/kubernetes.io~configmap/serviceca/..2023_06_02_02_53_07.3903481854/test.cchen.work..5000
    /var/lib/kubelet/pods/ee73918a-c16c-48be-9dfd-ba0d4577badf/volumes/kubernetes.io~configmap/serviceca/test.cchen.work..5000
    /var/lib/kubelet/pods/86894834-929d-4a24-8889-2c37a27194a0/volumes/kubernetes.io~configmap/registry-certificates/..2023_06_02_02_53_55.962570959/test.cchen.work..5000
    /var/lib/kubelet/pods/86894834-929d-4a24-8889-2c37a27194a0/volumes/kubernetes.io~configmap/registry-certificates/test.cchen.work..5000

    # This CA will be written to docker/certs.d

    /etc/docker/certs.d/test.cchen.work:5000
    /etc/docker/certs.d/test.cchen.work:5000/ca.crt
    ```

    So two Pods will be using the test.cchen.work..5000. See who are they:

    ```bash
    $ oc get pod -A -o json | jq '.items[] | select(.metadata.uid == "ee73918a-c16c-48be-9dfd-ba0d4577badf") | .metadata.name'
    node-ca-pkrp6

    $ oc get pods node-ca-pkrp6 -o yaml | grep config -A4

      - configMap:
          defaultMode: 420
          name: image-registry-certificates
        name: serviceca

    $ oc get pods node-ca-pkrp6 -o yaml | grep serviceca -B2

        - mountPath: /tmp/serviceca
          name: serviceca

    $ oc rsh node-ca-pkrp6
    sh-4.4$ cd /tmp/serviceca/
    sh-4.4$ ls
    image-registry.openshift-image-registry.svc..5000  image-registry.openshift-image-registry.svc.cluster.local..5000  test.cchen.work..5000

    ```

    ```bash
    $ oc get pod -A -o json | jq '.items[] | select(.metadata.uid == "86894834-929d-4a24-8889-2c37a27194a0") | .metadata.name'
    image-registry-6fcf9c8c5f-7dg8n

    $ oc get pods image-registry-6fcf9c8c5f-7dg8n -o yaml | grep config -A4

      - configMap:
          defaultMode: 420
          name: image-registry-certificates
        name: registry-certificates

    $ oc get pods image-registry-6fcf9c8c5f-7dg8n -o yaml | grep registry-certificates -B2

        - mountPath: /etc/pki/ca-trust/source/anchors
          name: registry-certificates

    $ oc rsh image-registry-6fcf9c8c5f-7dg8n
    sh-4.4$ cat /etc/pki/ca-trust/source/anchors/test.cchen.work..5000
    <The CA that we created>

    ```

   2. What's the point to set /etc/docker/certs.d/ if crio doesn't look at it?
<https://github.com/cri-o/cri-o/issues/4941>