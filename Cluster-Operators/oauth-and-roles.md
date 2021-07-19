####
~~~
$ oc get oauth cluster -o yaml
~~~
#### Change token expiration
~~~
OAuthClient:

RedirectURI
WWW-challenge
Token-max-age
 tokenConfig:
                accessTokenMaxAgeSeconds: 172800
~~~
#### Authentication Flow
~~~
Browser with Credentials -> OAuth -> Identity Provider -> Matched -> Pass Oauth -> Oauth returns token
$ oc login -u -p --loglevel=10

$ oc get oauth.config.openshift.io -o yaml
$ oc adm inspect co authentication

Case #02798430
~~~
#### Get cluster roles "edit"
~~~
$ oc get clusterroles edit -o yaml
$ oc describe clusterrole.rbac
~~~
~~~
$ oc get clusterrolebindings cluster-autoscaler -o yaml
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-autoscaler
subjects:
- kind: ServiceAccount
  name: cluster-autoscaler
  namespace: openshift-machine-api
~~~
#### Add role
~~~
$ oc adm policy add-role-to-user
$ oc adm policy who-can get nodes
~~~
#### ServiceAccount login
~~~
$ oc sa get-token <SA>
$ oc login --token=<Token>
$ oc scale dc/<DC> --replicas=3
~~~
####
KCS 5636901 4985361
#### HTPasswd
~~~
Get current htpasswd-secret

$ oc extract secret/htpasswd-secret \ > -n openshift-config --confirm --to /tmp/

$ htpasswd -D /tmp/htpasswd <user>

Replace the htpasswd-secret

$ oc set data secret/htpasswd-secret \ > -n openshift-config --from-file htpasswd=/tmp/htpasswd
~~~
#### SCC
~~~
https://www.openshift.com/blog/managing-sccs-in-openshift
~~~
