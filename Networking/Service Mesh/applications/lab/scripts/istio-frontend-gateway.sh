#!/bin/sh
oc apply -f istio-files/destination-rule-frontend.yml -n ${USERID}
oc apply -f istio-files/virtual-service-frontend-fault-inject.yml -n ${USERID}
oc apply -f istio-files/frontend-gateway.yml -n ${USERID}