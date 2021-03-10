#!/bin/bash
# $1 = X.Y.Z, $2 = RPM Package name
# Example:
# ./get_version.sh 4.12.18 cri-o

OCP_RELEASE="${1}"
PACKAGE="${2}"

OCP_MAJOR="$(echo "${OCP_RELEASE}" | awk -F. '{print $1"."$2}')"
RHCOS_VERSION="$(oc adm release info "${OCP_RELEASE}" -o jsonpath='{.displayVersions.machine-os.Version}')"
if [ $OCP_MAJOR != 4.13 ]; then
    URL="https://releases-rhcos-art.apps.ocp-virt.prod.psi.redhat.com/storage/prod/streams/${OCP_MAJOR}/builds/${RHCOS_VERSION}/x86_64/commitmeta.json"
else
    URL="https://releases-rhcos-art.apps.ocp-virt.prod.psi.redhat.com/storage/prod/streams/${OCP_MAJOR}-9.2/builds/${RHCOS_VERSION}/x86_64/commitmeta.json"
fi
#curl -sk "https://releases-rhcos-art.cloud.privileged.psi.redhat.com/storage/releases/rhcos-${OCP_MAJOR}/${RHCOS_VERSION}/x86_64/commitmeta.json" | jq -r '.["rpmostree.rpmdb.pkglist"]|map(select(.[0]=="'"${PACKAGE}"'"))[0]|.[0]+"-"+.[2]+"-"+.[3]+"."+.[4]'
curl -sk "https://releases-rhcos-art.apps.ocp-virt.prod.psi.redhat.com/storage/releases/rhcos-${OCP_MAJOR}/${RHCOS_VERSION}/x86_64/commitmeta.json" | jq -r '.["rpmostree.rpmdb.pkglist"]|map(select(.[0]=="'"${PACKAGE}"'"))[0]|.[0]+"-"+.[2]+"-"+.[3]+"."+.[4]'
curl -sk $URL | jq -r '.["rpmostree.rpmdb.pkglist"]|map(select(.[0]=="'"${PACKAGE}"'"))[0]|.[0]+"-"+.[2]+"-"+.[3]+"."+.[4]'
