# Mirror-registry

## Download mirror-registry binary

<https://console.redhat.com/openshift/downloads#tool-mirror-registry>

## Install mirror-registry

~~~bash

$ ./mirror-registry install --quayHostname quay-server.nancyge.com --quayRoot /var/mirror-registry --initPassword <password>

# The URL will be https://quay-server.nancyge.com:8443
# The credential is init:<password>
# The rootCA is under /var/mirror-registry/quay-rootCA

~~~

## Add Quay's rootCA to OpenShift image for Build

~~~bash

$ oc create configmap registry-cas -n openshift-config --from-file=quay-server.nancyge.com..8443=/tmp/rootCA.pem
$ oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"registry-cas"}}}' --type=merge

~~~

## Create Secret which Contains Quay Credential

~~~bash

$ cat /tmp/config.json
{
        "auths": {
                "quay-server.nancyge.com:8443": {
                        "auth": "aW5pdDpyZWXXXXXXXX"
                }
        }
}

$ oc create secret generic dockerhub --from-file=.dockerconfigjson=/tmp/config.json --type=kubernetes.io/dockerconfigjson

~~~

## Edit BuildConfig to use your own Quay

~~~bash

$ oc edit bc <BuildConfig>

spec:
  failedBuildsHistoryLimit: 5
  nodeSelector: null
  output:
    pushSecret:
      name: dockerhub
    to:
      kind: DockerImage
      name: quay-server.nancyge.com:8443/rhn_support_cchen/test-s2i:latest

~~~

## Test the Build

~~~bash
$ oc new-app https://github.com/cchen666/openshift-flask
$ oc start-build openshift-flask
$ oc logs openshift-flask-4-build -f
STEP 9/9: CMD /usr/libexec/s2i/run
COMMIT temp.builder.openshift.io/test-s2i/openshift-flask-4:613eecda
time="2022-08-31T12:32:12Z" level=warning msg="Adding metacopy option, configured globally"
Getting image source signatures
Copying blob sha256:5966005eac8d0b52bf676cd20f1ffb3435fe4d8245a3afadcd27b0b9e07c096b
Copying blob sha256:9936c6aaa811c2084fe2c1034e24cbecc3d3ac8db8fe987395723b19c678655b
Copying blob sha256:0ce645f59bfcd24ff75234e6567b6945cb9fd16fe18082485924d6db10d53326
Copying blob sha256:2d6812ade9b74a40c89aab889f858547544aff786125510af25ef98c8dd9a943
Copying blob sha256:bd8ba0c9fb84839bcfe68cf393dc08c4d20247c7040f3ca7e4a3a533f0b0d611
Copying blob sha256:8ca9f7a560a269937ca9e7d78ec1feb5ac95a42b19022510fccb85f676b3955d
Copying config sha256:a2398d0865c9993a30e817b2beb0d5fec5e557409e1fe50b38db0722af0dadd5
Writing manifest to image destination
Storing signatures
--> a2398d0865c
Successfully tagged temp.builder.openshift.io/test-s2i/openshift-flask-4:613eecda
a2398d0865c9993a30e817b2beb0d5fec5e557409e1fe50b38db0722af0dadd5

Pushing image quay-server.nancyge.com:8443/rhn_support_cchen/test-s2i:latest ...
Getting image source signatures
Copying blob sha256:8ca9f7a560a269937ca9e7d78ec1feb5ac95a42b19022510fccb85f676b3955d
Copying blob sha256:354c079828fae509c4f8e4ccb59199d275f17b0f26b1d7223fd64733788edf32
Copying blob sha256:7e3624512448126fd29504b9af9bc034538918c54f0988fb08c03ff7a3a9a4cb
Copying blob sha256:db0f4cd412505c5cc2f31cf3c65db80f84d8656c4bfa9ef627a6f532c0459fc4
Copying blob sha256:e0dc1b5a4801cf6fec23830d5fcea4b3fac076b9680999c49935e5b50a17e63b
Copying blob sha256:436bf753eb551f22d718c0fa7103efc29841a1f958cef5a29525ce8f7660ae0b
Copying config sha256:a2398d0865c9993a30e817b2beb0d5fec5e557409e1fe50b38db0722af0dadd5
Writing manifest to image destination
Storing signatures
Successfully pushed quay-server.nancyge.com:8443/rhn_support_cchen/test-s2i@sha256:f35764bb4c7dab311c9d32491d04064c10b61c04cc88f5449b47d8af30b2f7b2
Push successful

~~~
