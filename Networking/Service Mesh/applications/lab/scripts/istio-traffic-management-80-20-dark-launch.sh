#!/bin/sh
oc apply -f istio-files/virtual-service-backend-v1-v2-mirror-to-v3.yml -n $USERID
