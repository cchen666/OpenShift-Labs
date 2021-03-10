#!bin/sh
export FRONTEND_URL=http://$(oc get route frontend -n $USERID -o jsonpath='{.spec.host}')
echo FRONTEND_URL=$FRONTEND_URL
export KIALI_URL=https://$(oc get route kiali -o jsonpath='{.spec.host}' -n $USERID-istio-system)
echo KIALI_URL=$KIALI_URL
export JAEGER_URL=https://$(oc get route jaeger -o jsonpath='{.spec.host}' -n $USERID-istio-system)
echo JAEGER_URL=$JAEGER_URL
export GATEWAY_URL=$(oc get route $(oc get route -n $USERID-istio-system | grep frontend | awk '{print $1}') -n $USERID-istio-system -o yaml  -o jsonpath='{.spec.host}')
echo GATEWAY_URL=$GATEWAY_URL

