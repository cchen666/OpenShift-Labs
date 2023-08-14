# OAuth and Roles

## Get oauth CR

```bash
$ oc get oauth cluster -o yaml
```

## Change token expiration

```bash
OAuthClient:

RedirectURI
WWW-challenge
Token-max-age
 tokenConfig:
                accessTokenMaxAgeSeconds: 172800
```

## Authentication Flow

```bash
Browser with Credentials -> OAuth -> Identity Provider -> Matched -> Pass Oauth -> Oauth returns token
$ oc login -u -p --loglevel=10

$ oc get oauth.config.openshift.io -o yaml
$ oc adm inspect co authentication

Case #02798430
```

## Get cluster roles "edit"

```bash
$ oc get clusterroles edit -o yaml
$ oc describe clusterrole.rbac
```

```bash
$ oc get clusterrolebindings cluster-autoscaler -o yaml
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-autoscaler
subjects:
- kind: ServiceAccount
  name: cluster-autoscaler
  namespace: openshift-machine-api
```

## Add role

```bash
$ oc adm policy add-role-to-user
$ oc adm policy who-can get nodes
```

## ServiceAccount login

```bash
$ oc sa get-token <SA>
$ oc login --token=<Token>
$ oc scale dc/<DC> --replicas=3
```

## Known Issues

KCS 5636901 4985361

## HTPasswd

```bash
Get current htpasswd-secret

$ oc extract secret/htpasswd-secret \ > -n openshift-config --confirm --to /tmp/

$ htpasswd -D /tmp/htpasswd <user>

Replace the htpasswd-secret

$ oc set data secret/htpasswd-secret \ > -n openshift-config --from-file htpasswd=/tmp/htpasswd
```

## SCC

```bash
<https://www.openshift.com/blog/managing-sccs-in-openshift>
```

## OAuth flow

```bash
$ oc login -u yaoli -p 'RedHat1!' -v=10 > /tmp/login.txt 2>&1

$ cat /tmp/login.txt


$ grep curl /tmp/login.txt

I0728 22:58:42.514081   13413 round_trippers.go:423] curl -k -v -XGET  -H "X-Csrf-Token: 1" 'https://api.mycluster.nancyge.com:6443/.well-known/oauth-authorization-server'

This .well-known/oatu-ahtorization-server is open without credentials needed.



I0728 22:58:43.527938   13413 round_trippers.go:423] curl -k -v -XGET  -H "X-Csrf-Token: 1" 'https://oauth-openshift.apps.mycluster.nancyge.com/oauth/authorize?client_id=openshift-challenging-client&code_challenge=DNaWdLtTTW254L0ySzzv6jSOaztVCLa1ugPP5LaPVxQ&code_challenge_method=S256&redirect_uri=https%3A%2F%2Foauth-openshift.apps.mycluster.nancyge.com%2Foauth%2Ftoken%2Fimplicit&response_type=code'
I0728 22:58:44.245938   13413 round_trippers.go:423] curl -k -v -XGET  -H "Authorization: Basic eWFvbGk6UmVkSGF0MSE=" -H "X-Csrf-Token: 1" 'https://oauth-openshift.apps.mycluster.nancyge.com/oauth/authorize?client_id=openshift-challenging-client&code_challenge=DNaWdLtTTW254L0ySzzv6jSOaztVCLa1ugPP5LaPVxQ&code_challenge_method=S256&redirect_uri=https%3A%2F%2Foauth-openshift.apps.mycluster.nancyge.com%2Foauth%2Ftoken%2Fimplicit&response_type=code'

The method is oauth/authorize. Pay attention to the parameter:

client_id=openshift-challenging-client: This means it is from Cli
code_challenge: PKCE protocal(rfc7636): a random string(code_verifier) and transformed by some algorithm defined in code_challenge_method.
code_challenge_method: SHA256

In normal situation, the attacker could retrieve the Auth code and use the Auth code to get access_token. By using PKCE, we send code_challenge value to the Auth server along with other information and Auth server returns us Auth code. Then we use code_verifier + Auth code to get access_token. The Auth server will compare code_verifier and code_challenge and if it matches then access_token will return.

                                          +-------------------+
                                          |   Authz Server    |
+--------+                                | +---------------+ |
|        |--(A)- Authorization Request ---->|               | |
|        |       + t(code_verifier), t_m  | | Authorization | |
|        |                                | |    Endpoint   | |
|        |<-(B)---- Authorization Code -----|               | |
|        |                                | +---------------+ |
| Client |                                |                   |
|        |                                | +---------------+ |
|        |--(C)-- Access Token Request ---->|               | |
|        |          + code_verifier       | |    Token      | |
|        |                                | |   Endpoint    | |
|        |<-(D)------ Access Token ---------|               | |
+--------+                                | +---------------+ |
                                          +-------------------+

More details: https://fusionauth.io/docs/v1/tech/oauth/endpoints/#token
https://datatracker.ietf.org/doc/html/rfc7636

I0728 22:58:44.599854   13413 round_trippers.go:423] curl -k -v -XPOST  -H "Authorization: Basic b3BlbnNoaWZ0LWNoYWxsZW5naW5nLWNsaWVudDo=" -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: application/json" 'https://oauth-openshift.apps.mycluster.nancyge.com/oauth/token'

Method is POST oauth/token. I am suspecting the log missed some required parameters such as code_verifier, grant_types etc according to https://fusionauth.io/docs/v1/tech/oauth/endpoints/#token ?
```
