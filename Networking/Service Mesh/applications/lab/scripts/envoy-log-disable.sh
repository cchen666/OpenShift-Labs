#!/bin/sh
 oc get configmap istio -n ${USERID}-istio-system -o yaml \
  | sed 's/accesLogFile: "\/dev\/stdout/accessLogFile: ""/g' \
  | oc replace -n ${USERID}-istio-system -f -
# accessLogEncoding: 'TEXT'
 oc get configmap istio -n ${USERID}-istio-system -o yaml \
  | sed "s/accessLogEncoding: 'TEXT'/accessLogEncoding: ''/g" \
  | oc replace -n ${USERID}-istio-system -f -

