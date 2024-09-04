#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 <OCP_VERSION> <PACKAGE_NAME>"
    exit 1
fi

OCP_VERSION=$1
PACKAGE_NAME=$2

sudo cp /var/lib/kubelet/config.json /tmp/
sudo chmod 755 /tmp/config.json

image=`curl -s -N https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OCP_VERSION/release.txt | grep machine-os-content | awk '{print $2}'`
podman run --rm --authfile /tmp/config.json -it --entrypoint /bin/cat $image /pkglist.txt | grep $PACKAGE_NAME