#!/bin/sh
oc apply -f istio-files/authentication-frontend-enable-mtls.yml -n $USERID
oc apply -f istio-files/destination-rule-frontend-mtls.yml -n $USERID
oc apply -f istio-files/virtual-service-frontend.yml -n $USERID
oc apply -f istio-files/frontend-gateway.yml -n $USERID
