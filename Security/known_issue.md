# Known Issue

## Can't use secured route cert ?

```bash

oc create route edge --service=openshift-flask --cert=fullchain.pem --key=privkey.pem --hostname=helloworld.nancyge.com

# helloworld.nancyge.com points to LB
# fullchain.pem and privkey.pem has helloworld.nancyge.com SAN DNS

$  echo Q | openssl s_client -connect helloworld.nancyge.com:443 | openssl x509 -text

            X509v3 Subject Alternative Name:
                DNS:*.apps.mycluster.nancyge.com

          X509v3 Subject Alternative Name:
                DNS:*.apps.mycluster.nancyge.com

# As the above shows, helloworld.nancyge.com still uses *.apps cert instead its own cert. So edge route can't use its own cert ?

```
