#!/bin/sh
echo "Setup environment"
oc apply -f ocp/frontend-v1-deployment.yml -n $USERID
oc apply -f ocp/frontend-service.yml -n $USERID
oc apply -f ocp/frontend-route.yml -n $USERID
oc apply -f ocp/backend-v1-deployment.yml -n $USERID
oc apply -f ocp/backend-v2-deployment.yml -n $USERID
oc apply -f ocp/backend-service.yml -n $USERID
watch oc get pods -n $USERID
echo "Create Pod without sidecar"
oc apply -f ocp/station-deployment.yml -n $USERID
echo "Create istio policies"
oc apply -f istio-files/destination-rule-backend-v1-v2-mtls.yml -n $USERID
oc apply -f istio-files/virtual-service-backend-v1-v2-50-50.yml -n $USERID
oc apply -f istio-files/authentication-backend-enable-mtls.yml -n $USERID
