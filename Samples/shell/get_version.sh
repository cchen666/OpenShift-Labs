#!/bin/bash
# $1 = X.Y.Z, $2 = RPM Package name
# Example:
# ./get_version.sh 4.12.18 cri-o

OCP_RELEASE="${1}"
PACKAGE="${2}"
RHCOS_VERSION="$(oc adm release info "${OCP_RELEASE}" -o jsonpath='{.displayVersions.machine-os.Version}')"
OCP_MAJOR="$(echo "${OCP_RELEASE}" | awk -F. '{print $1"."$2}')"
case $OCP_MAJOR in
    4.19)
        OCP_VERSION="4.19-9.6"
        ;;
    4.18)
        OCP_VERSION="4.18-9.4"
        ;;
    4.17)
        OCP_VERSION="4.17-9.4"
        ;;
    4.16)
        OCP_VERSION="4.16-9.4"
        ;;
    4.15)
        OCP_VERSION="4.15-9.4"
        ;;
    4.14)
        OCP_VERSION="4.14-9.2"
        ;;
    4.13)
        OCP_VERSION="4.13-9.2"
        ;;
    *)
        OCP_VERSION=${OCP_MAJOR}
        ;;
esac
URL="https://releases-rhcos--prod-pipeline.apps.int.prod-stable-spoke1-dc-iad2.itup.redhat.com/storage/prod/streams/${OCP_VERSION}/builds/${RHCOS_VERSION}/x86_64/commitmeta.json"
curl -sk $URL | jq -r '.["rpmostree.rpmdb.pkglist"]|map(select(.[0]=="'"${PACKAGE}"'"))[0]|.[0]+"-"+.[2]+"-"+.[3]+"."+.[4]'
