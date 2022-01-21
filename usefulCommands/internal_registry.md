# Internal Registry Useful Commands

## Get image tag

~~~bash

curl -u cchen:redhat -k https://10.0.138.30:5000/v2/olm-mirror/openshift4-ose-elasticsearch-operator/tags/list
podman image inspect 10.0.138.30:5000/olm-mirror/openshift4-ose-elasticsearch-operator:68e3d583

~~~
