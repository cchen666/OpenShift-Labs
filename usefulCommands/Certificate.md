# Certificate

## See expiration date

~~~bash
$ oc get secret -A -o json | jq -r '.items[] | select(.metadata.annotations."auth.openshift.io/certificate-not-after"!=null) | select(.metadata.name|test("-[0-9]+$")|not) | "\(.metadata.namespace) \(.metadata.name) \(.metadata.annotations."auth.openshift.io/certificate-not-after")"' | column -t
~~~

<https://www.sfernetes.com/2021/12/24/kubernetes-cert/>

## See kubelet Trusted CA Root

~~~bash
$ cat /var/lib/kubelet/kubeconfig | grep certificate-authority-data: | awk '{print $2}' | base64 -d | openssl crl2pkcs7 -certfile /dev/stdin -nocrl | openssl pkcs7 -print_certs -text  -in /dev/stdin | grep Issuer -A5
        Issuer: OU=openshift, CN=kube-apiserver-lb-signer
        Validity
            Not Before: Sep  1 05:08:58 2022 GMT
            Not After : Aug 29 05:08:58 2032 GMT
        Subject: OU=openshift, CN=kube-apiserver-lb-signer
        Subject Public Key Info:
--
        Issuer: OU=openshift, CN=kube-apiserver-localhost-signer
        Validity
            Not Before: Sep  1 05:08:58 2022 GMT
            Not After : Aug 29 05:08:58 2032 GMT
        Subject: OU=openshift, CN=kube-apiserver-localhost-signer
        Subject Public Key Info:
--
        Issuer: OU=openshift, CN=kube-apiserver-service-network-signer
        Validity
            Not Before: Sep  1 05:08:58 2022 GMT
            Not After : Aug 29 05:08:58 2032 GMT
        Subject: OU=openshift, CN=kube-apiserver-service-network-signer
        Subject Public Key Info:
--
        Issuer: CN=openshift-kube-apiserver-operator_localhost-recovery-serving-signer@1662009819
        Validity
            Not Before: Sep  1 05:23:39 2022 GMT
            Not After : Aug 29 05:23:40 2032 GMT
        Subject: CN=openshift-kube-apiserver-operator_localhost-recovery-serving-signer@1662009819
        Subject Public Key Info:
~~~
