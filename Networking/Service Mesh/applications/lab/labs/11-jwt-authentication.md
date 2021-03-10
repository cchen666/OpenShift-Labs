# Secure Service with JWT Authentication

<!-- TOC -->

- [Secure Service with JWT Authentication](#secure-service-with-jwt-authentication)
  - [Setup](#setup)

<!-- /TOC -->
Istio sidecar can validate JWT token as defined by RFC 7519. You can check more detail in OpenID connect 1.0 (OIDC) and OAuth 2.0

## Setup

* Create frontend and backend application with destination rule, virtual service and gateway for frontend. Actually you also need to enable TLS to secure token. Check steps in [Secure with TLS](09-securing-with-mTLS.md) if you want.

  ```bash
    DOMAIN=$(oc whoami --show-console | awk -F'apps.' '{print $2}')
    oc delete dr,vs --all -n $USERID
    oc delete serviceentry --all -n $USERID
    oc delete gateway frontend-gateway -n $USERID
    oc delete all --all -n $USERID
    oc apply -f ocp/frontend-v1-deployment.yaml -n $USERID
    oc patch deployment frontend-v1 -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject":"true"}}}}}' -n $USERID
    oc apply -f ocp/frontend-service.yaml -n $USERID
    oc apply -f ocp/backend-v1-deployment.yaml -n $USERID
    oc apply -f ocp/backend-v2-deployment.yaml -n $USERID
    oc apply -f ocp/backend-service.yaml -n $USERID
    cat istio-files/destination-rule-backend-v1-v2.yaml|sed s/USERID/$USERID/g|oc apply -n $USERID -f -
    cat istio-files/virtual-service-backend-v1-v2-50-50.yaml|sed s/USERID/$USERID/g|sed s/DOMAIN/$DOMAIN/g|oc apply -n $USERID -f -
    cat istio-files/destination-rule-frontend.yaml|sed s/USERID/$USERID/g|oc apply -n $USERID -f -
    cat istio-files/virtual-service-frontend-single-version.yaml|sed s/USERID/$USERID/g|sed s/DOMAIN/$DOMAIN/g|oc apply -n $USERID -f -
    cat istio-files/gateway.yaml | sed s/USERID/$USERID/ | sed s/DOMAIN/$DOMAIN/ | oc apply -n $USERID -f -
  ```

<!-- ```bash
oc delete -f ocp/frontend-route.yml -n $USERID
oc apply -f ocp/frontend-v1-deployment.yml -n $USERID
oc apply -f ocp/frontend-service.yml -n $USERID
oc apply -f ocp/backend-v1-deployment.yml -n $USERID
oc apply -f ocp/backend-v2-deployment.yml -n $USERID
oc apply -f ocp/backend-service.yml -n $USERID
oc apply -f istio-files/virtual-service-frontend.yml -n $USERID
watch oc get pods -n $USERID
oc apply -f istio-files/frontend-gateway.yml -n $USERID
``` -->

## Authentication Policy

Review [frontend-jwt-with-mtls.yml.yml](../istio-files/frontend-jwt-with-mtls.yml)

```yaml
spec:
  targets:
  - name: frontend
    ports:
    - number: 8080
  #Remove peer with mtls if Frontend is not enabled with mTLS
  peers:
  - mtls: {}
  origins:
  - jwt:
      issuer: "http://localhost:8080/auth/realms/quickstart"
      audiences:
      - "curl"
      jwksUri: "https://gitlab.com/workshop6/service-mesh/raw/master/keycloak/jwks.json"
      triggerRules:
      - excludedPaths:  
        - exact: /version
```

This authentication policy is configured with

* Target service is frontend
* Issuer (iss) must be http://localhost:8080/auth/realms/quickstart
* URL of the provider’s public key set to validate signature of the JWT is located at https://gitlab.com/workshop6/service-mesh/raw/master/keycloak/jwks.json

Apply authentication policy 

```bash
oc delete -f istio-files/authentication-frontend-enable-mtls.yml -n $USERID
oc apply -f istio-files/frontend-jwt-with-mtls.yml -n $USERID
```

For testing purpose, JWT token that satisfied with above requirments is genereated by Red Hat Single Sign-On (or its upstream Keycloak) and also set token validity period to 10 years (This is for simplied steps for test JWT. Normally, default validity duration of token is 1 minutes)

You can check JWT token by get content of [jwt.txt](../keycloak/jwt.txt) and decode with [jwt.io](http://jwt.io)

Another token ([jwt-wrong-realm.txt](../keycloak/jwt-wrong-realm.txt) is generated with another Issuer for testing.

Following show decoded JWT token. Check for iss that is same value as issuer in authentication policy

![JWT Decoded](../images/jwt-decoded.png)

### Test

JWT authentication is specified in HTTP header as follow.

```bash
Authorization: Bearer <token>
```

Test with token which issue from invalid issuer.

```bash
GATEWAY_URL=$(oc get route frontend -n $USERID-istio-system -o jsonpath='{.spec.host}')
TOKEN=$(cat keycloak/jwt-wrong-realm.txt)
curl -v --header "Authorization: Bearer $TOKEN" $GATEWAY_URL
```

Sample output

```bash
....
< HTTP/1.1 401 Unauthorized
...
...
Origin authentication failed.* Closing connection 0
```

Test again with valid JWT token

```bash
TOKEN=$(cat keycloak/jwt.txt)
curl --header "Authorization: Bearer $TOKEN" $GATEWAY_URL
```

With valid JWT token, you will get response from Frontend app.

```bash
Frontend version: v1 => [Backend: http://backend:8080, Response: 200, Body: Backend version:v2, Response:200, Host:backend-v2-7699759f8f-8pxj8, Status:200, Message: Hello, World]
```

Test excluded URI (/version) without Bearer token.

```bash
curl -v $GATEWAY_URL/version
```
## Optional - Load test with K6

Open [load-test/load-test-jwt.js](../load-test/load-test-jwt.js) and replaced url with $GATEWAY_URL

```js
...
export default function () {
  var url = 'http://frontend.apps.cluster-ada4.ada4.example.opentlc.com';
  let res=http.get(url);
...
```
Run load test with K6 from pod with **oc run** command

```bash
 oc run jwt-perf -n $USERID \
    -i --image=loadimpact/k6  \
    --rm=true --restart=Never --  run -< load-test/load-test-jwt.js
```
Or run locally from your machine by
```bash
docker run -i loadimpact/k6 run -<  load-test/load-test-jwt.js
```
## Clean Up

Run oc delete command to remove Istio policy.

```bash
oc delete -f istio-files/frontend-jwt-authentication.yml -n $USERID
oc delete -f istio-files/frontend-gateway.yml -n $USERID
oc delete -f istio-files/virtual-service-frontend.yml -n $USERID
```

<!-- ## Next Topic

[Rate Limits](./10-rate-limits.md) -->

