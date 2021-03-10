#!/bin/sh
echo "Check Control Plane Status"
oc get smcp -n ${USERID}-istio-system
echo "====================================="
echo "Check Member Roll"
oc get smmr -n ${USERID}-istio-system
echo "====================================="
oc describe smmr default -n ${USERID}-istio-system
