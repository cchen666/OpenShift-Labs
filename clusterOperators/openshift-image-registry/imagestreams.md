# ImageStream

<https://www.tutorialworks.com/openshift-imagestreams/>

## Create ImageStream

### Method 1

~~~bash
$ oc import-image approved-apache:2.4 \
    --from=bitnami/apache:2.4 \
    --confirm
~~~

### Method 2

~~~bash
# We can't use "oc tag bitnami/apache:2.4 cchentest:latest2"

$ oc tag docker.io/bitnami/apache:2.4 approved-apache:2.4
~~~

### Method 3

~~~bash
$ oc apply -f files/imagestream.yaml
~~~

## Use ImageStream in Deployment

~~~bash
$ oc import-image my-python --from=quay.io/tdonohue/python-hello-world:latest --confirm
$ oc new-app --image-stream=my-python
$ oc get deploy -o yaml
<Snip>
      spec:
        containers:
        - image: quay.io/tdonohue/python-hello-world@sha256:f1de5bdd753e51d65693496025000f7581c47a4946e01c3d3baf94a50284d988
~~~

## Use ImageStream in BuildConfig Source

~~~bash
$ cat files/buildconfig.yaml
~~~
