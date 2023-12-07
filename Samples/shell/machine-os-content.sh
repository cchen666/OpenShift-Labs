#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <OCP_VERSION>"
    exit 1
fi

packageList='kernel,cri-o,runc'

image=`curl -s -N https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$1/release.txt | grep machine-os-content | awk '{print $2}'`
podman run --rm --authfile /tmp/config.json -it --entrypoint $image /bin/cat /etc/redhat-release
for package in "${packageList[@]}"; do
    podman run --rm --authfile /tmp/config.json -it --entrypoint $image /bin/cat /pkglist.txt | grep $package
done