# HTPasswd Auth Provider

## Create htpasswd File

~~~bash

$ htpasswd -bBc /tmp/htpasswd.txt cchen redhat
$ oc create secret generic htpass-secret --from-file=htpasswd=/tmp/htpasswd.txt -n openshift-config

~~~

## Patch Identity Provider

~~~bash

$ cat <<EOF | oc apply -f -
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: my_htpasswd_provider
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret

EOF
~~~

## Bind ClusterRole

~~~bash

$ oc adm policy add-cluster-role-to-user cluster-admin cchen

~~~
