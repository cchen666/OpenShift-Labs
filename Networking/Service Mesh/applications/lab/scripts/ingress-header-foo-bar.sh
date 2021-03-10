#!/bin/sh
oc apply -f istio-files/destination-rule-frontend-v1-v2.yml -n $USERID
oc apply -f istio-files/virtual-service-frontend-header-foo-bar-to-v1.yml -n $USERID
export GATEWAY_URL=$(oc -n $USERID-istio-system get route istio-ingressgateway -o jsonpath='{.spec.host}')
echo "Istio Gateway:$GATEWAY_URL"
