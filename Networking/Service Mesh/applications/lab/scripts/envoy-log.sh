#!/bin/sh
 oc get configmap istio -n ${USERID}-istio-system -o yaml \
  | sed 's/accessLogFile: ""/accesLogFile: "\/dev\/stdout"/g' \
  | oc replace -n ${USERID}-istio-system -f -
# accessLogEncoding: 'TEXT'
 oc get configmap istio -n ${USERID}-istio-system -o yaml \
  | sed "s/accessLogEncoding: ''/accessLogEncoding: 'TEXT'/g" \
  | oc replace -n ${USERID}-istio-system -f -
