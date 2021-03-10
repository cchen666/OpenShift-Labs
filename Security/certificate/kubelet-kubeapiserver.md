# Kubelet Certificate

## kube-apiserver <----> kubelet

### Case 1. Client: kube-apiserver; Server: kubelet

#### Item 1. kubelet certificate and Key as the server, in short, kubelet-server-cert-key

* Path: `/var/lib/kubelet/pki/kubelet-server-current.pem`
* Verication

1. Dump the server certificate

    ~~~bash
    $ echo Q | openssl s_client -connect 192.168.0.109:10250 | openssl x509 -text -noout

    <Snip>
            Issuer: CN = kube-csr-signer_@1670558493
            Validity
                Not Before: Dec  9 06:00:46 2022 GMT
                Not After : Jan  8 04:01:34 2023 GMT
            Subject: O = system:nodes, CN = system:node:multi-osp-24dll-worker-0-lxqxw # Pay attention to the CN as the user, O as the group to authenticate. Yes the certificate extracts the user and group for further authenticate. This is called certificate-based authentication. Check clientCAFile later
                X509v3 Subject Alternative Name:
                    DNS:multi-osp-24dll-worker-0-lxqxw, IP Address:192.168.0.109
    <Snip>

    ~~~

2. Compare the above dumped server with `/var/lib/kubelet/pki/kubelet-server-current.pem` and they are 100% same

#### Item 2. kubelet trusted CA as the server

* Path: `/etc/kubernetes/kubelet-ca.crt`

~~~bash
$ cat /etc/kubernetes/kubelet.conf
<Snip>
authentication:
  x509:
    clientCAFile: /etc/kubernetes/kubelet-ca.crt
~~~

* clientCAFile: clientCAFile is the path to a PEM-encoded certificate bundle. If set, any request presenting a client certificate signed by one of the authorities in the bundle is authenticated with a username corresponding to the CommonName, and groups corresponding to the Organization in the client certificate.

<https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/#kubelet-config-k8s-io-v1beta1-KubeletX509Authentication>

* The connections from the API server to the kubelet are used for fetching logs for pods, attaching (through kubectl) to running pods, and using the kubelet’s port-forwarding functionality. These connections terminate at the kubelet’s HTTPS endpoint. By default, the API server does not verify the kubelet’s serving certificate, which makes the connection subject to man-in-the-middle attacks, and unsafe to run over untrusted and/or public networks. Enabling Kubelet certificate authentication ensures that the API server could authenticate the Kubelet before submitting any requests.

<https://docs.datadoghq.com/security/default_rules/cis-kubernetes-1.5.1-4.2.3/>

* Verification:

~~~bash
$ openssl x509 -in /etc/kubernetes/kubelet-ca.crt -text -noout
<Snip>
        Issuer: OU = openshift, CN = admin-kubeconfig-signer
        Validity
            Not Before: Dec  8 08:41:04 2022 GMT
            Not After : Dec  5 08:41:04 2032 GMT # 10 years validation for this CA cert
        Subject: OU = openshift, CN = admin-kubeconfig-signer
            X509v3 Basic Constraints: critical
                CA:TRUE

~~~

#### Item 3. kube-apiserver cert and key as the client

#### Item 4. CSR

* After adding the worker node:

~~~bash
$ oc get csr
NAME        AGE   SIGNERNAME                                    REQUESTOR                                                                   REQUESTEDDURATION   CONDITION
csr-9wtnx   71m   kubernetes.io/kubelet-serving                 system:node:multi-osp-24dll-worker-0-t99gt                                  <none>              Approved,Issued
csr-xm6xp   71m   kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper   <none>              Approved,Issued
~~~

* Compare the `csr-9wtnx` with kubelet serving cert, the same:

~~~bash

$ oc get csr csr-9wtnx -ojsonpath={.status.certificate} | base64 -d | openssl x509 -text -noout
<Snip>
        Issuer: CN = kube-csr-signer_@1670558493
        Validity
            Not Before: Dec 13 12:00:19 2022 GMT
            Not After : Jan  8 04:01:34 2023 GMT
        Subject: O = system:nodes, CN = system:node:multi-osp-24dll-worker-0-t99gt
            X509v3 Subject Alternative Name:
                DNS:multi-osp-24dll-worker-0-t99gt, IP Address:192.168.0.179


$ oc get csr csr-9wtnx -ojsonpath={.status.certificate} | base64 -d | openssl x509 -text -noout | md5sum
de704accec6addf18e5fd0232ab65f06  -

$ oc debug node/multi-osp-24dll-worker-0-t99gt
sh-4.4# chroot /host
sh-4.4# openssl x509 -in /var/lib/kubelet/pki/kubelet-server-current.pem -text -noout | md5sum
de704accec6addf18e5fd0232ab65f06  -

~~~

* Now check `csr-xm6xp`, it looks to be kubelet-client cert because it has node name as CN (username) and system:nodes as Org (group) but it has no SAN. It should be in Case 2.

~~~bash
$ oc get csr csr-xm6xp -ojsonpath={.status.certificate} | base64 -d | openssl x509 -text -noout
<Snip>
        Issuer: CN = kube-csr-signer_@1670558493
        Validity
            Not Before: Dec 13 12:00:06 2022 GMT
            Not After : Jan  8 04:01:34 2023 GMT
        Subject: O = system:nodes, CN = system:node:multi-osp-24dll-worker-0-t99gt
        Subject Public Key Info:

$ oc get csr csr-xm6xp -ojsonpath={.status.certificate} | base64 -d | openssl x509 -text -noout | md5sum
19360a040d7ec3fe3c95debe8ba3deea  -

$ oc debug node/multi-osp-24dll-worker-0-t99gt
sh-4.4# chroot /host
sh-4.4# openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -text -noout | md5sum
19360a040d7ec3fe3c95debe8ba3deea  -

~~~

### Case 2: Client: kubelet; Server: kube-apiserver

#### Item1: kube-apiserver certificate and key as server

#### Item2: kube-apiserver trusted CA

#### Item3: kubelet certificate and key as client

## Ref

<https://jvns.ca/blog/2017/08/05/how-kubernetes-certificates-work/>
<https://www.youtube.com/watch?v=gXz4cq3PKdg>
<https://kubernetes.io/docs/reference/access-authn-authz/kubelet-authn-authz/>
