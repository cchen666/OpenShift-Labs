# Operator SDK for GoLang

## Install packages and download operator-sdk

~~~bash
# yum install gcc make
~~~

## Initial the operator and create API

~~~bash
# operator-sdk init --domain=example.com --repo=github.com/example/memcached-operator

# operator-sdk create api --group=cache --version=v1alpha1 --kind=Memcached
~~~
