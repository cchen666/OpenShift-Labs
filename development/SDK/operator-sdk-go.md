# Operator SDK for GoLang

<https://docs.openshift.com/container-platform/4.8/operators/operator_sdk/golang/osdk-golang-tutorial.html>

## Download operator-sdk and opm Package and Install Necessary Build Tools

~~~bash
# I'm using OCP 4.8.24 so make sure you are using golang 1.16. For 4.9 make sure you are using golang 1.17 and so on
# Extract the operator-sdk and opm tar.gz file and copy the binary to /usr/local/bin and add x permission
$ wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/operator-sdk/4.8.25/operator-sdk-v1.8.2-ocp-darwin-x86_64.tar.gz
$ wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/4.8.24/opm-mac-4.8.24.tar.gz
$ yum install gcc make -y
~~~

## Initialize the Operator and Create API

~~~bash
$ mkdir memcached-operator
$ cd memcached-operator
$ operator-sdk init --domain=cchen666.github.io --repo=github.com/cchen666/memcached-operator
$ operator-sdk create api --group=cache --version=v1alpha1 --kind=Memcached
~~~

## Implement Spec and Status to api/v1alpha1/memcached_types.go

~~~go
type MemcachedSpec struct {
    // +kubebuilder:validation:Minimum=0
    // Size is the size of the memcached deployment
    Size int32 `json:"size"`
}

type MemcachedStatus struct {
    // Nodes are the names of the memcached pods
    Nodes []string `json:"nodes"`
}
~~~

## Update Generated Code and Create Manifests

~~~bash
$ make generate
$ make manifests
~~~

## Implement controllers/memcached_controller.go

~~~bash
# You can directly use files/memcached_controller.go.sample
$ cp <path>/files/memcached_controller.go.sample controllers/memcached_controller.go
$ make manifests
~~~

## Change the Makefile to Your Own Registry Info

~~~makefile
IMAGE_TAG_BASE ?= quay.io/rhn_support_cchen/memcached-operator
IMG ?= $(IMAGE_TAG_BASE):latest
~~~

## Build the Operator and Push Operator Image to quay.io

~~~bash
$ make docker-build
$ make docker-push
~~~

## Build the Bundle and Push Bundle Image to quay.io

~~~bash
$ make bundle
$ make bundle-build
$ make bundle-push
~~~

## Build the CatalogSource and Push Index Image to quay.io

~~~bash
$ make catalog-build
$ make catalog-push
~~~

## Install the CatalogSource and Push to quay.io

~~~bash
$ oc apply -f <path>/files/catalogsource.yaml
~~~

## Install the Operator in WebUI OperatorHub

~~~bash
# You see your own Operator and the Operator could be installed
$ oc get pods -n openshift-operators | grep memcached
memcached-operator-controller-manager-548bf664f9-4qt7m   2/2     Running     0          26s
~~~

## Very Good Example

<https://github.com/jianzhangbjz/learn-operator>