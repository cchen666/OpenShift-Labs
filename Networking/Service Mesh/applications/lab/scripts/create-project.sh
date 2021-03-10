#!/bin/sh
echo "Create projects for $USERID"
oc new-project $USERID --display-name="Data Plane" --description="Data Plane"
oc new-project $USERID-istio-system --display-name="Control Plane"  --description="Service Mesh Control Plane"
oc new-project $USERID-load-test --display-name="Load Test"  --description="Load Test and Web Terminal"
