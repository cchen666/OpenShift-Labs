#!/bin/sh
 oc get configmap istio -n ${USERID}-istio-system -o yaml \
  | sed 's/mode: ALLOW_ANY/mode: REGISTRY_ONLY/g' \
  | oc replace -n ${USERID}-istio-system -f -