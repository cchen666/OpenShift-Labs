#!/bin/sh
oc apply -f istio-files/virtual-service-backend.yml -n $USERID
oc apply -f istio-files/destination-rule-backend-circuit-breaker-with-pool-ejection.yml -n $USERID
