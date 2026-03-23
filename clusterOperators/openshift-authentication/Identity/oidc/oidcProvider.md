# OIDC Provider

## Create oc-cli-test and console-test clients in Keycloak

## Edit Authentication.config

```bash
$ oc edit config authentication.config.openshift.io/cluster

```yaml
spec:
  oidcProviders:
  - claimMappings:
      extra:
      - key: example.com/role
        valueExpression: claims.?role.orValue("unknown")
      groups:
        claim: groups
        prefix: ""
      uid:
        claim: sub
      username:
        claim: email
        prefix:
          prefixString: 'oidc-user-test:'
        prefixPolicy: Prefix
    issuer:
      audiences:
      - console-test
      - oc-cli-test
      issuerCertificateAuthority:
        name: keycloak-oidc-ca
      issuerURL: https://keycloak-keycloak.apps.test.lab.local/auth/realms/openshift
    name: keycloak-oidc-server
    oidcClients:
    - clientID: oc-cli-test
      componentName: cli
      componentNamespace: openshift-console
    - clientID: console-test
      clientSecret:
        name: console-secret
      componentName: console
      componentNamespace: openshift-console
      extraScopes:
      - email
      - profile
  type: OIDC
```

## Login to the console

## Login to the CLI

```
$ oc login --exec-plugin=oc-oidc     --issuer-url=https://keycloak-keycloak.apps.test.lab.local/auth/realms/openshift     --client-id=oc-cli-test     --extra-scopes=email --callback-port=8082     --oidc-certificate-authority /tmp/ca.txt
```