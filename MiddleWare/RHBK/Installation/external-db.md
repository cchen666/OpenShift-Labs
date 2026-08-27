# Guide: Deploying Keycloak on OpenShift with an External PostgreSQL Database (VM) - v2

This guide walks you through setting up a highly available **Red Hat build of Keycloak 26.6 cluster** on **OpenShift** (3+2 nodes) that points to an external **PostgreSQL** database hosted on a dedicated **Virtual Machine (VM)**.

---

## Architecture Overview

*   **Keycloak Layer:** Deployed on OpenShift as a multi-instance cluster managed by the **Red Hat build of Keycloak Operator**.
*   **Database Layer:** PostgreSQL installed on a Virtual Machine (e.g., RHEL 9). The database is initialized with Keycloak's required UTF8 charset, collation settings, and optimal upgrade privileges.
*   **Connection Security:** Secure communication on port `5432` from the OpenShift pod network to the VM.

---

## Step 1: Install PostgreSQL on the VM (RHEL/CentOS)

Run these commands on your dedicated VM to install and configure PostgreSQL:

1. **Install PostgreSQL packages:**
   ```bash
   sudo dnf install -y postgresql-server postgresql-contrib
   ```

2. **Initialize the database subsystem:**
   ```bash
   sudo postgresql-setup --initdb
   ```

3. **Enable and start the PostgreSQL service:**
   ```bash
   sudo systemctl enable --now postgresql
   ```

4. **Configure PostgreSQL to listen on VM network interfaces:**
   Open `/var/lib/pgsql/data/postgresql.conf` in your favorite editor and find the `listen_addresses` line. Uncomment it and set it to listen on all interfaces (or your specific cluster network interface):
   ```ini
   listen_addresses = '*'
   ```

5. **Configure client authentication to allow OpenShift Pod traffic:**
   Edit `/var/lib/pgsql/data/pg_hba.conf` to allow Keycloak database connections from the OpenShift cluster's SDN pod IP range (or simply allow any network connection using `0.0.0.0/0` for demo purposes):
   ```text
   # TYPE  DATABASE        USER            ADDRESS                 METHOD
   host    keycloak        keycloak        0.0.0.0/0                scram-sha-256
   ```

6. **Restart PostgreSQL to apply configuration changes:**
   ```bash
   sudo systemctl restart postgresql
   ```

7. **Open Port 5432 in the local OS firewall:**
   ```bash
   sudo firewall-cmd --add-port=5432/tcp --permanent
   sudo firewall-cmd --reload
   ```

---

## Step 2: Initialize the Keycloak Database

Log into the PostgreSQL instance on the VM as a superuser and set up the UTF8-encoded database, database user, and essential metadata table permissions required by Keycloak:

1. **Log in to PostgreSQL CLI:**
   ```bash
   sudo -u postgres psql
   ```

2. **Create the Keycloak User First:**
   To make user ownership mapping seamless, we define the role before creating the database:
   ```sql
   CREATE USER keycloak WITH PASSWORD 'your_secure_password_here';
   ```

3. **Create the Database with UTF8 Encoding & Assign Ownership:**
   Keycloak requires consistent database charsets and collations. **Assigning the owner as `keycloak` is critical** because, starting with PostgreSQL 15+, the default `CREATE` privileges on the `public` schema have been restricted to the database owner or superusers. If the database is created without explicit ownership, the `keycloak` user will receive "permission denied for schema public" errors during Keycloak's initial schema migration.
   ```sql
   CREATE DATABASE keycloak OWNER keycloak ENCODING 'UTF8' LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8';
   ```

4. **Connect to the `keycloak` Database and Grant Metadata Permissions:**
   Keycloak queries RDBMS metadata tables during upgrades to estimate table row counts efficiently [10.7.2]. Granting `SELECT` privileges to `pg_class` and `pg_namespace` prevents slow fallback execution during schema updates [10.7.2]:
   ```sql
   \c keycloak
   GRANT USAGE, CREATE ON SCHEMA public TO keycloak;
   GRANT SELECT ON pg_catalog.pg_class TO keycloak;
   GRANT SELECT ON pg_catalog.pg_namespace TO keycloak;
   ```

---

## Step 3: Configure OpenShift and the Keycloak Operator

With the database listening on the VM, perform these configurations on your OpenShift cluster using `oc`:

1. **Create the Keycloak target namespace:**
   ```bash
   $ oc create ns keycloak
   ```

2. **Create a Secret containing the database credentials:**
   The Keycloak Operator references database credentials from an Opaque Secret in the same namespace.
   ```bash
   oc create secret generic keycloak-db-secret \
     --from-literal=username=keycloak \
     --from-literal=password=your_secure_password_here \
     -n keycloak
   ```

3. **Configure the Keycloak Custom Resource (CR):**
   Apply the provided `keycloak-external-db-cr-v2.yaml` manifest. This configures Keycloak to connect to your PostgreSQL VM, run **2 replica pods** for high availability, and optimize connection pooling.

   ```yaml
   apiVersion: k8s.keycloak.org/v2beta1
   kind: Keycloak
   metadata:
     name: keycloak-external-db
     namespace: keycloak
   spec:
     instances: 3
     db:
       vendor: postgres
       host: <POSTGRES_VM_IP> # Specify the VM IP Address
       port: 5432
       database: keycloak
       usernameSecret:
         name: keycloak-db-secret
         key: username
       passwordSecret:
         name: keycloak-db-secret
         key: password
       # Optimal pool sizing based on Keycloak HA recommendations
       poolMinSize: 30
       poolInitialSize: 30
       poolMaxSize: 30
     http:
       httpEnabled: true
     proxy:
       headers: xforwarded
     hostname:
       hostname: keycloak.apps.your-cluster.example.com # Specify the target host router URL
   ```

   Apply the Custom Resource:
   ```bash
   oc apply -f keycloak-external-db-cr-v2.yaml
   ```

4. **Verify Deployment & Retrieve Admin Credentials:**
   Check the deployment status of Keycloak:
   ```bash
   oc get keycloak keycloak-external-db -n keycloak -o jsonpath='{.status.conditions}'
   ```

   Once the Keycloak pods are up, extract the auto-generated initial administrator credentials to access the Admin Console:
   ```bash
   oc get secret keycloak-external-db-initial-admin -n keycloak -o jsonpath='{.data.username}' | base64 --decode && echo ""
   oc get secret keycloak-external-db-initial-admin -n keycloak -o jsonpath='{.data.password}' | base64 --decode && echo ""
   ```
