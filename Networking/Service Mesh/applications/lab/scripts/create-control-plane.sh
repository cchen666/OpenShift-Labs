#!/bin/sh
echo "Create Control Plane for $USERID"
echo "All istio's pods will run in project $USERID-istio-system"
oc apply -f install/basic-install.yaml -n $USERID-istio-system
watch oc get smcp/basic -n $USERID-istio-system
