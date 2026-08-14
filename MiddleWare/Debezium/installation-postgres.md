
This guide walks you through setting up an end-to-end Change Data Capture (CDC) pipeline using Debezium on Podman (hosted on your local VM) and Apache Kafka deployed on OpenShift (exposed via OpenShift Routes with TLS). It includes detailed instructions for configuring PostgreSQL replication, creating a Java truststore for self-signed certificates, and registering your connector.

---
+-----------------------------------------------------------------------------------+
 |  HOST MACHINE                                                                     |
 |                                                                                   |
 |   +----------------------+                                                        |
 |   |  Keycloak App / DB   |                                                        |
 |   |                      |                                                        |
 |   |  [postgresql.conf]   |                                                        |
 |   |  wal_level = logical |                                                        |
 |   |                      |                                                        |
 |   |  [Database: keycloak]|                                                        |
 |   |  └── Schema: public  |                                                        |
 |   |       └── user_entity|                                                        |
 |   +----------+-----------+                                                        |
 |              |                                                                    |
 |              | WAL / Replication Stream (dbz_publication)                          |
 |              v                                                                    |
 |   +---------------------------------------------------------------------------+   |
 |   |  Podman Container: "connect" (quay.io/debezium/connect:3.6)               |   |
 |   |                                                                           |   |
 |   |  - Connects to Host via: host.containers.internal:5432                    |   |
 |   |  - Truststore: /kafka/config/certs/strimzi-ca.crt (PEM)                   |   |
 |   |  - Connector: pg-user-connector                                           |   |
 |   |  - Converter: schemas.enable = false (Clean JSON Payload)                 |   |
 |   +-------------------------------------+-------------------------------------+   |
 +-----------------------------------------|-----------------------------------------+
                                           |
                                           | mTLS / TLS Passthrough (Port 443)
                                           v
 +-----------------------------------------------------------------------------------+
 |  OPENSHIFT CLUSTER (Namespace: streams-kafka)                                     |
 |                                                                                   |
 |   +---------------------------------------------------------------------------+   |
 |   |  Strimzi Kafka Cluster (my-cluster)                                       |   |
 |   |                                                                           |   |
 |   |  OpenShift Ingress Route (Port 443 Passthrough)                           |   |
 |   |        │                                                                  |   |
 |   |        v                                                                  |   |
 |   |  Kafka Topic: [ vm-pg.public.user_entity ]                                |   |
 |   |        │                                                                  |   |
 |   |        v                                                                  |   |
 |   |  Consumer: kafka-console-consumer.sh                                      |   |
 |   +---------------------------------------------------------------------------+   |
 +-----------------------------------------------------------------------------------+


## Architecture Overview
1. **Source**: PostgreSQL database on a Virtual Machine.
2. **CDC Engine**: Debezium running in a **Podman** container on the same VM.
3. **Event Broker**: Apache Kafka running on **OpenShift**, exposed securely via wild-card TLS Routes.
4. **Consumer**: A lightweight pod running inside OpenShift to watch events.

[ Debezium Change Data Capture ]
PostgreSQL (keycloak)
  └─ user_entity Table (Change occurs)
       └─ WAL Log
            └─ dbz_publication (Filters for user_entity changes)
                 └─ Debezium Engine (Reads stream & converts to JSON)
                      └─ Kafka Topic: vm-pg.public.user_entity
---

## Step 1: Configure PostgreSQL on your VM

Debezium’s PostgreSQL connector captures changes by reading the Write-Ahead Log (WAL) via logical replication slots.

### 1. Update `postgresql.conf`
Edit your `postgresql.conf` file (typically located in `/var/lib/pgsql/data/` or `/etc/postgresql/<version>/main/`) to enable logical replication:

```ini
# REPLICATION CONFIGURATION
wal_level = logical             # Required for logical decoding and replication slots
max_wal_senders = 4             # Number of concurrent tasks streaming WAL changes
max_replication_slots = 4       # Max replication slots the database will allocate
```
*Note: You must restart the PostgreSQL service to apply these changes.*

### 2. Configure a Replication User
Log into your PostgreSQL shell as a superuser and create a dedicated replication user with the necessary permissions:

```sql
-- Create replication-enabled user
CREATE USER debezium WITH REPLICATION LOGIN PASSWORD 'dbz';

-- Grant standard permissions to let the user connect and read tables
\c keycloak -- Grant connect and create privileges on the keycloak DB
GRANT CONNECT, CREATE ON DATABASE keycloak TO debezium; -- Grant schema and table privileges inside keycloak DB
GRANT USAGE ON SCHEMA public TO debezium;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO debezium; -- Set replica identity for the Keycloak user table

-- 1. Create the publication for the user_entity table directly
CREATE PUBLICATION dbz_publication FOR TABLE public.user_entity;
-- 2. Grant ownership/access of this publication to debezium
ALTER PUBLICATION dbz_publication OWNER TO debezium;
ALTER TABLE public.user_entity REPLICA IDENTITY DEFAULT;
```

### 3. Update Host-Based Authentication (`pg_hba.conf`)
Ensure your `pg_hba.conf` allows replication connections from the local container host IP subnet:

```text
# Allow replication connections locally and from the Podman container subnet
local   replication     all                                     trust
host    replication     debezium        0.0.0.0/0               trust
host    keycloak        debezium        0.0.0.0/0               trust
```
Apply the changes by running:
```sql
SELECT pg_reload_conf();
```

---

## Step 2: Deploy Apache Kafka on OpenShift

Using the **Strimzi Operator** on OpenShift, we will deploy a cluster and expose it to external VM clients using native **OpenShift Routes** (which leverage HAProxy with SNI and TLS).

### 1. Create a Dedicated Project
```bash
oc new-project debezium-example
```

### 2. Deploy the Strimzi Kafka Operator
Go to your OpenShift Console, navigate to **OperatorHub**, search for **Strimzi**, and click **Install** using the default settings.

### 3. Deploy the Kafka Cluster with Route Listener
Save the following YAML as `kafka-cluster.yaml`. It sets up ephemeral storage and an external route listener on port `9094`:

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaNodePool
metadata:
  name: debezium-cluster-node-pool
  labels:
    strimzi.io/cluster: debezium-cluster
spec:
  replicas: 3
  roles:
    - broker
    - controller
  storage:
    type: ephemeral
---
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: debezium-cluster
spec:
  kafka:
    version: "3.9.0"
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
      # This exposes Kafka externally using OpenShift Routes
      - name: external
        port: 9094
        type: route
        tls: true
    config:
      offsets.topic.replication.factor: 3
      transaction.state.log.replication.factor: 3
      transaction.state.log.min.isr: 2
      default.replication.factor: 3
      min.insync.replicas: 2
  entityOperator:
    topicOperator: {}
    userOperator: {}
```

Apply the configuration:
```bash
oc apply -f kafka-cluster.yaml -n debezium-example
```

Wait for the cluster to become ready:
```bash
oc wait kafka/debezium-cluster --for=condition=Ready --timeout=300s -n debezium-example
```

### 4. Retrieve the Bootstrap Route Address
Run the following command to retrieve the public ingress domain generated for your Kafka bootstrap server:
```bash
oc get routes -n debezium-example debezium-cluster-kafka-bootstrap -o jsonpath='{.spec.host}'
```
*Take note of the host address (e.g., `debezium-cluster-kafka-bootstrap-debezium-example.apps.mycluster.domain`). You will connect on port **443** (since the route forces TLS).*

---

## Step 3: Establish Trust for the Self-Signed Certificate

Because OpenShift's default wildcard route certificate is self-signed, Debezium must explicitly trust it to establish a handshake.

### 1. Extract the Wildcard SSL Certificate
Connect to the bootstrap Route on port `443` from your VM and extract the certificate:

```bash
openssl s_client -showcerts -connect <YOUR_OPENSHIFT_BOOTSTRAP_ROUTE_URL>:443 </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > openshift-ingress-ca.crt
```

### 2. Generate a PKCS12 Truststore
Import the certificate into a Java-compatible PKCS12 truststore:

```bash
openssl pkcs12 -export \
  -nokeys \
  -in openshift-ingress-ca.crt \
  -out truststore.p12 \
  -name openshift-route-ca \
  -passout pass:mysecretpassword
```

Move the generated `truststore.p12` file to a secure directory on your VM:
```bash
sudo mkdir -p /opt/debezium/secrets
sudo mv truststore.p12 /opt/debezium/secrets/
sudo chmod 644 /opt/debezium/secrets/truststore.p12
sudo chmod 755 /opt/debezium/secrets
```

---

## Step 4: Run Debezium Connect on Podman

Run Debezium inside a Podman container on your VM. We will mount the directory containing your certificate truststore and configure all internal Kafka client communications (Producer, Consumer, Admin) to use TLS and trust your custom store.

```bash
YOUR_OPENSHIFT_BOOTSTRAP_ROUTE_URL=my-cluster-kafka-bootstrap-streams-kafka.apps.ocp420.domain.com
```
*(The `:Z` flag ensures SELinux allows Podman to read the mounted `/opt/debezium/secrets` directory).*

---

## Step 5: Register the PostgreSQL Connector

Because the Debezium PostgreSQL connector relies strictly on PG logical replication slots (`pgoutput`), it does **not** require a schema history topic (which is unique to databases like MySQL or SQL Server). Hence, no additional pass-through SSL configurations are needed within the connector config itself.

### 1. Create `register-postgres.json`
Save the following configuration as `register-postgres.json` on your VM. Replace `database.hostname` with your VM's IP address (visible from the Podman container gateway):

```json
{
  "name": "pg-user-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "tasks.max": "1",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "false",
    "database.hostname": "host.containers.internal",
    "database.port": "5432",
    "database.user": "debezium",
    "database.password": "dbz",
    "database.dbname": "keycloak",
    "topic.prefix": "vm-pg",
    "plugin.name": "pgoutput",
    "publication.autocreate.mode": "disabled",
    "publication.name": "dbz_publication",
    "schema.include.list": "public",
    "table.include.list": "public.user_entity"
  }
}
```

### 2. Submit Connector Configuration
Use `curl` to submit the payload to the running Debezium REST API:

```bash
curl -i -X POST \
  -H "Accept:application/json" \
  -H "Content-Type:application/json" \
  http://localhost:8083/connectors/ \
  -d @register-postgres.json
```

Verify that the connector is active and running:
```bash
curl -s http://localhost:8083/connectors/pg-user-connector/status
{"name":"pg-user-connector","connector":{"state":"RUNNING","worker_id":"10.88.0.7:8083","version":"3.6.1.Final"},"tasks":[{"id":0,"state":"RUNNING","worker_id":"10.88.0.7:8083","version":"3.6.1.Final"}],"type":"source"}
```

To Delete:
```bash
curl -i -X DELETE http://localhost:8083/connectors/pg-user-connector
```
---

## Step 6: Verify and Consume Change Events

To verify that your data changes are successfully reaching your OpenShift cluster, deploy a lightweight consumer container inside OpenShift to view the events as they land on the topic.

### 1. Check we see the kafka topic we want
Run an interactive watcher pod in your OpenShift project that connects directly to the internal bootstrap service:

```bash
oc exec -n streams-kafka my-cluster-mixed-0 -c kafka -- \
  bin/kafka-topics.sh --bootstrap-server localhost:9092 --list | grep vm-pg
vm-pg.public.user_entity
```

### 2. Trigger User Creation in Keycloak and Monitor the Kafka
Once we create the specific user, the event will be sent to the kafka and we could tell it:

```bash
oc exec -n streams-kafka -it my-cluster-mixed-0 -c kafka -- \
  bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic vm-pg.public.user_entity \
  --from-beginning

{"before":null,"after":{"id":"3f9ac4bb-2045-4144-b4a5-254dd32efea7","email":null,"email_constraint":"009d054a-a026-4e51-b0a1-d467bc555cb4","email_verified":false,"enabled":false,"federation_link":null,"first_name":null,"last_name":null,"realm_id":"99336381-a1ac-4d6c-af62-c3293683f786","username":"jqk","created_timestamp":1786521216034,"service_account_client_link":null,"not_before":0},"source":{"version":"3.6.1.Final","connector":"postgresql","name":"vm-pg","ts_ms":1786521216043,"snapshot":"false","db":"keycloak","sequence":"[\"32355064\",\"32381200\"]","ts_us":1786521216043006,"ts_ns":1786521216043006000,"schema":"public","table":"user_entity","txId":1254,"lsn":32381200,"xmin":null,"origin":null,"origin_lsn":null},"transaction":null,"op":"c","ts_ms":1786521216075,"ts_us":1786521216075518,"ts_ns":1786521216075518177}
{"before":null,"after":{"id":"3f9ac4bb-2045-4144-b4a5-254dd32efea7","email":null,"email_constraint":"b076536a-72aa-4d2e-a5ed-d2227e152450","email_verified":false,"enabled":true,"federation_link":null,"first_name":null,"last_name":null,"realm_id":"99336381-a1ac-4d6c-af62-c3293683f786","username":"jqk","created_timestamp":1786521216034,"service_account_client_link":null,"not_before":0},"source":{"version":"3.6.1.Final","connector":"postgresql","name":"vm-pg","ts_ms":1786521216043,"snapshot":"false","db":"keycloak","sequence":"[\"32355064\",\"32396944\"]","ts_us":1786521216043006,"ts_ns":1786521216043006000,"schema":"public","table":"user_entity","txId":1254,"lsn":32396944,"xmin":null,"origin":null,"origin_lsn":null},"transaction":null,"op":"u","ts_ms":1786521216076,"ts_us":1786521216076694,"ts_ns":1786521216076694012}
```

