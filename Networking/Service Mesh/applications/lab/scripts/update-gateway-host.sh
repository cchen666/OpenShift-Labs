#!/bin/sh
VIRTUAL_GATEWAY=frontend-virtual-service
GATEWAY=$(oc get route istio-ingressgateway -n ${USERID}-istio-system -o jsonpath='{.spec.host}')
oc get VirtualService/${VIRTUAL_GATEWAY} -o yaml -n ${USERID}| \
sed "s/\*/$GATEWAY/g" | \
oc replace -n ${USERID} -f -
GATEWAY_HOST=$(oc get VirtualService/${VIRTUAL_GATEWAY} -o jsonpath='{.spec.hosts[0]}' -n ${USERID})
echo "Virtual Gateway ${VIRTUAL_GATEWAY} host is set to ${GATEWAY_HOST}"