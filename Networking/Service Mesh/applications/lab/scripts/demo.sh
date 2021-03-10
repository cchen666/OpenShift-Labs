#!/bin/sh
banner (){
    echo ""
    echo "***********************************************************************************"
    echo "${1}"
    echo "***********************************************************************************"
    read -p ""
}
echo "Deploy Demo Apps on project ${USERID}"
scripts/deploy.sh
echo "Deploy Control Plane"
scripts/create-control-plane.sh

source scripts/get-urls.sh
banner "Press enter to produce some workload. Check Kiali and Jeager Console"
siege -c 1 ${FRONTEND_URL}
banner "Apply destination rule and virtual service for backend to split 80/20"
scripts/istio-traffic-management-80-20.sh
banner "Press enter to produce some workload. Check Kiali Console for traffic percentage"
siege -c 1 ${FRONTEND_URL}
banner "Add timeout 3sec. From now on, reqeust to v2 will received 504"
scripts/istio-traffic-management-50-50-timeout.sh
siege -c 1 ${FRONTEND_URL}
banner "Remove timeout 3 sec"
scripts/istio-traffic-management-50-50.sh
banner "Create Istio Gateway"
scripts/istio-frontend-gateway.sh
echo "GATEWAY_URL:http://${GATEWAY_URL}"
sleep 10
banner "Press enter to produce some workload throgh Istio Gateway"
sleep 10
siege -c 1 ${GATEWAY_URL}
banner "Fault will be injected if header foo=bar"
echo ""
set -x
curl -v -s -H foo:bar ${GATEWAY_URL}
set +x
banner " Check for result"
banner "Enable REGISTRY_ONLY mode for outgoing traffic"
scripts/registry-only-mode.sh
echo "Wait for 15 sec"
sleep 15
siege -c 1 ${GATEWAY_URL}
banner "Crate egress ServiceEntry"
scripts/istio-egress-gateway.sh
echo "Wait for 15 sec"
sleep 15
siege -c 1 ${GATEWAY_URL}
banner "enable mTLS"
echo "Create Pod without sidecar"
oc apply -f ocp/station-deployment.yml -n $USERID
oc apply -f istio-files/destination-rule-backend-v1-v2-mtls.yml -n $USERID
oc apply -f istio-files/virtual-service-backend-v1-v2-50-50.yml -n $USERID
oc apply -f istio-files/authentication-backend-enable-mtls.yml -n $USERID
oc apply -f istio-files/authentication-frontend-enable-mtls.yml -n $USERID
oc apply -f istio-files/destination-rule-frontend-mtls.yml -n $USERID
oc apply -f istio-files/virtual-service-frontend.yml -n $USERID
oc apply -f istio-files/frontend-gateway.yml -n $USERID
siege -c 1 ${GATEWAY_URL}
banner "enable JWT Authentication"
oc apply -f istio-files/frontend-jwt-with-mtls.yml -n $USERID
banner "Test with invalid JWT Token"
set -x
TOKEN=$(cat keycloak/jwt-wrong-realm.txt)
curl --header "Authorization: Bearer $TOKEN" $GATEWAY_URL
set +x
banner "Test with vilid JWT Token"
set -x
TOKEN=$(cat keycloak/jwt.txt)
curl --header "Authorization: Bearer $TOKEN" $GATEWAY_URL
set +x
banner "Route will not work because mTLS is required"
set -x
TOKEN=$(cat keycloak/jwt.txt)
curl --header "Authorization: Bearer $TOKEN" $FRONTEND_URL
banner "Tear down..."
scripts/teardown.sh 2>/dev/null
