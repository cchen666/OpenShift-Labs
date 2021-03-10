#!/bin/sh
oc apply -f ocp/frontend-v1-deployment.yaml -n $USERID
oc apply -f ocp/backend-v1-deployment.yaml -n $USERID
oc apply -f ocp/backend-v2-deployment.yaml -n $USERID
oc patch deployment/frontend-v1 -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject":"true"}}}}}' -n $USERID
oc apply -f ocp/backend-service.yaml -n $USERID
#oc apply -f ocp/frontend-v2-deployment.yaml -n $USERID
oc apply -f ocp/frontend-service.yaml -n $USERID
oc apply -f ocp/frontend-route.yaml -n $USERID
watch oc get pods -n $USERID
export FRONTEND_URL=http://$(oc get route frontend -n $USERID -o jsonpath='{.status.ingress[0].host}')
echo "Frontend URL:${FRONTEND_URL}"