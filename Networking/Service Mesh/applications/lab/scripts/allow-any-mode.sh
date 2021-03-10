 oc get configmap istio -n ${USERID}-istio-system -o yaml \
  | sed 's/mode: REGISTRY_ONLY/mode: ALLOW_ANY/g' \
  | oc replace -n ${USERID}-istio-system -f -