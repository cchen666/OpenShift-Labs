#!/bin/sh
oc apply -f ocp/backend-v3-deployment.yml -n $USERID
oc apply -f ocp/backend-v3-service.yml -n $USERID

