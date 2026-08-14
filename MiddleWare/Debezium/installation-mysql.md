# Installation of Debezium on MySQL

## Mysql Configuration

    ```
    # cat /etc/my.cnf.d/mysql-server.cnf
    [mysqld]
    server-id               = 223344
    log-bin                 = mysql-bin
    binlog_format           = ROW
    binlog_row_image        = FULL
    binlog_expire_logs_seconds = 864000
    ```

## Create a new user for Debezium

    ```sql
    sudo mysql -u root <<'SQL'
    CREATE DATABASE keycloak CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
    CREATE USER 'keycloak'@'%' IDENTIFIED BY 'mysql';
    GRANT ALL PRIVILEGES ON keycloak.* TO 'keycloak'@'%';
    FLUSH PRIVILEGES;
    SQL
    ```

## Run the Debezium connector

    ```sh
    $ echo YOUR_KAFKA_BOOTSTRAP_SERVERS="my-cluster-kafka-bootstrap-streams-kafka.apps.example.com:443" > /opt/debezium/secrets/bootstrap.servers
    $ podman run -d --name connect \
    -p 8083:8083 \
    -v /opt/debezium/secrets:/kafka/config/certs:Z \
    -e GROUP_ID=1 \
    -e CONFIG_STORAGE_TOPIC=my-connect-configs \
    -e OFFSET_STORAGE_TOPIC=my-connect-offsets \
    -e STATUS_STORAGE_TOPIC=my-connect-statuses \
    -e BOOTSTRAP_SERVERS="${YOUR_KAFKA_BOOTSTRAP_SERVERS}:443" \
    -e CONNECT_SECURITY_PROTOCOL=SSL \
    -e CONNECT_SSL_TRUSTSTORE_LOCATION=/kafka/config/certs/strimzi-ca.crt \
    -e CONNECT_SSL_TRUSTSTORE_TYPE=PEM \
    -e CONNECT_PRODUCER_SECURITY_PROTOCOL=SSL \
    -e CONNECT_PRODUCER_SSL_TRUSTSTORE_LOCATION=/kafka/config/certs/strimzi-ca.crt \
    -e CONNECT_PRODUCER_SSL_TRUSTSTORE_TYPE=PEM \
    -e CONNECT_CONSUMER_SECURITY_PROTOCOL=SSL \
    -e CONNECT_CONSUMER_SSL_TRUSTSTORE_LOCATION=/kafka/config/certs/strimzi-ca.crt \
    -e CONNECT_CONSUMER_SSL_TRUSTSTORE_TYPE=PEM \
    quay.io/debezium/connect:3.6
    ```

## Register the connector

    ```sh
    $ curl -X POST -H "Content-Type: application/json" \
    --data @files/mariadb.json \
    http://localhost:8083/connectors
    ```

## Verify the connector

    ```sh
    $ curl -X GET http://localhost:8083/connectors/my-connector/status
    ```

## Check the events in the Kafka topic.

Pay attention to

1. The table for mariadb is USER_ENTITY, uppercase.
2. The schema for mariadb is keycloak, not `public`, which is used by PostgreSQL.

    ```bash
    $ oc exec -n streams-kafka -it my-cluster-mixed-0 -c kafka -- \
    bin/kafka-console-consumer.sh \
    --bootstrap-server localhost:9092 \
    --topic vm-mysql.keycloak.USER_ENTITY \
    --from-beginning
    ```
