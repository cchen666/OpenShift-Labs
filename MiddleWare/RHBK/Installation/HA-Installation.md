# High-Availability Red Hat build of Keycloak 26.6 Setup Summary

This document summarizes the steps and architecture used to deploy a highly available (HA), production-ready Red Hat build of Keycloak 26.6 cluster on OpenShift with CloudNativePG (CNPG) as the database backend and wildcard TLS edge routing.

---

## 1. Deploy the Database Layer (CloudNativePG)

We provisioned a highly available, synchronously replicated database using the CloudNativePG Operator:

1. Created the `cnpg-keycloak` namespace:

   ```bash
   oc create ns cnpg-keycloak
   ```

2. Applied the database cluster manifest (`cnpg-keycloak-db.yaml`) containing:
   - **3 PostgreSQL instances** spread across availability zones using pod anti-affinity (`topology.kubernetes.io/zone`).
   - **Synchronous replication** (1 synchronous standby) for zero-data-loss durability.
   - Disabled default read-only and read services (`disabledDefaultServices: ["ro", "r"]`), as Keycloak only connects to the primary read-write service [22, 23].

---

## 2. Secure Cross-Namespace Connections

To allow Keycloak (running in `keycloak` namespace) to securely communicate with the PostgreSQL cluster (running in `cnpg-keycloak` namespace):

1. **Replicated Database Credentials:**
   Extracted the auto-generated database user credentials from the `cnpg-keycloak-app` secret in `cnpg-keycloak` and created a replicated secret named `keycloak-db-secret` in the `keycloak` namespace:

   ```bash
   oc get secret cnpg-keycloak-app --namespace cnpg-keycloak -o go-template='
   apiVersion: v1
   kind: Secret
   metadata:
     name: keycloak-db-secret
     namespace: keycloak
   type: Opaque
   data:
     username: {{ .data.username }}
     password: {{ .data.password }}
   ' | oc apply -f -
   ```

2. **Exposed Database CA Certificate:**
   Created a ConfigMap named `cnpg-keycloak-ca` in the `keycloak` namespace containing the database cluster's CA certificate to establish server-side TLS verification (`db-tls-mode: verify-server`) [430]:

   ```bash
   oc --namespace keycloak create configmap cnpg-keycloak-ca \
     --from-literal=cert.pem="$(oc --namespace cnpg-keycloak get secrets cnpg-keycloak-ca -o jsonpath='{.data.ca\.crt}' | base64 -d)"
   ```

---

## 3. Deploy the Keycloak Cluster CR (`v2beta1`)

We deployed the Keycloak custom resource (`keycloak-ha-cr-v3.yaml`) using the officially supported `k8s.keycloak.org/v2beta1` API version [55, 57]:

- **High Availability:** Set `instances: 3` [44]. Keycloak nodes coordinate session replication and caching automatically using Infinispan and JGroups [441].
- **Proxy Configuration:** Since TLS termination is handled by the OpenShift router, we disabled the default operator ingress (`spec.ingress.enabled: false`), enabled Keycloak's HTTP listener (`spec.http.httpEnabled: true`), and configured Keycloak to trust reverse proxy headers (`spec.proxy.headers: xforwarded`) [53].
- **Database Connection:** Connected Keycloak to the primary read-write service endpoint (`cnpg-keycloak-rw.cnpg-keycloak.svc.cluster.local`) and set connection pool limits (`poolMinSize`, `poolInitialSize`, and `poolMaxSize` to `30`).
- **Truststore Mount:** Referenced the database CA certificate ConfigMap in `spec.truststores` so that Keycloak truststore can verify the PostgreSQL certificate [430].

---

## 4. Expose Keycloak via Wildcard Edge TLS Route

We exposed Keycloak using the default wildcard SSL/TLS certificate of the OpenShift Cluster's Ingress Controller:

1. Applied the custom Route manifest (`route.yaml`).
2. Configured **Edge TLS Termination** (`tls.termination: edge`). This delegates the SSL handshake/decryption to the OpenShift router using the cluster's wildcard certificate and proxies traffic over unencrypted HTTP (port `8080`) to the Keycloak pods.
3. Automatically redirects insecure HTTP requests to HTTPS (`tls.insecureEdgeTerminationPolicy: Redirect`).

---

## 5. Retrieve Initial Admin Credentials

Once the pods are running, retrieve the automatically generated master realm administrator credentials [88, 91] by running:

```bash
oc get secret keycloak-initial-admin -n keycloak -o jsonpath='{.data.username}' | base64 --decode
echo ""
oc get secret keycloak-initial-admin -n keycloak -o jsonpath='{.data.password}' | base64 --decode
echo ""
```