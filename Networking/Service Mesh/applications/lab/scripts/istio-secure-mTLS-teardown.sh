#!/bin/sh
oc delete -f istio-files/authentication-frontend-enable-mtls.yml -n $USERID
oc delete -f istio-files/destination-rule-frontend-mtls.yml -n $USERID
oc delete -f istio-files/virtual-service-frontend.yml -n $USERID
oc delete -f istio-files/destination-rule-backend-v1-v2-mtls.yml -n $USERID
oc delete -f istio-files/virtual-service-backend-v1-v2-50-50.yml -n $USERID
oc delete -f istio-files/authentication-backend-enable-mtls.yml -n $USERID
oc delete -f istio-files/frontend-gateway.yml -n $USERID
oc delete -f ocp/station-deployment.yml -n $USERID
