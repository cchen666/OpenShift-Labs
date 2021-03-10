# Standalone Quay

## Installation

~~~bash
$ sudo yum install -y podman conmon
$ sudo podman login registry.redhat.io
Username: <username>
Password: <password>
$ firewall-cmd --permanent --add-port=80/tcp
$ firewall-cmd --permanent --add-port=443/tcp
$ firewall-cmd --permanent --add-port=5432/tcp
$ firewall-cmd --permanent --add-port=5433/tcp
$ firewall-cmd --permanent --add-port=6379/tcp
$ firewall-cmd --reload
~~~

## Start postgres

~~~bash
$ mkdir /root/quay
$ export QUAY=/root/quay
$ mkdir -p $QUAY/postgres-quay
$ setfacl -m u:26:-wx $QUAY/postgres-quay

$ sudo podman run -d --rm --name postgresql-quay \
  -e POSTGRESQL_USER=quayuser \
  -e POSTGRESQL_PASSWORD=quaypass \
  -e POSTGRESQL_DATABASE=quay \
  -e POSTGRESQL_ADMIN_PASSWORD=adminpass \
  -p 5432:5432 \
  -v /root/quay/postgres-quay:/var/lib/pgsql/data:Z \
  registry.redhat.io/rhel8/postgresql-10:1

$ sudo podman exec -it postgresql-quay /bin/bash -c 'echo "CREATE EXTENSION IF NOT EXISTS pg_trgm" | psql -d quay -U postgres'
~~~

## Start Redis

~~~bash
$ sudo podman run -d --rm --name redis \
  -p 6379:6379 \
  -e REDIS_PASSWORD=strongpassword \
  registry.redhat.io/rhel8/redis-5:1
~~~

## Configure Quay and Download the config.yaml

~~~bash
$ sudo podman run --rm -it --name quay_config -p 80:8080 -p 443:8443 registry.redhat.io/quay/quay-rhel8:v3.6.6 config secret
~~~

## Start Quay

~~~bash
$
$ podman run -d --rm -p 80:8080 -p 443:8443     --name=quay    -v /root/quay/config:/conf/stack:Z    -v /root/quay/storage:/datastorage:Z    registry.redhat.io/quay/quay-rhel8:v3.6.6
~~~

openssl req -new -sha256 \
    -key /etc/crts/cert.key \
    -subj "/O=Local Cert/CN=quay-server.example.com" \
    -reqexts SAN \
    -config <(cat /etc/pki/tls/openssl.cnf \
        <(printf "\n[SAN]\nsubjectAltName=DNS:quay-server.example.com\nbasicConstraints=critical, CA:FALSE\nkeyUsage=digitalSignature, keyEncipherment, keyAgreement, dataEncipherment\nextendedKeyUsage=serverAuth")) \
    -out /etc/crts/cert.csr

openssl x509 \
    -req \
    -sha256 \
    -extfile <(printf "subjectAltName=DNS:quay-server.example.com\nbasicConstraints=critical, CA:FALSE\nkeyUsage=digitalSignature, keyEncipherment, keyAgreement, dataEncipherment\nextendedKeyUsage=serverAuth") \
    -days 3650 \
    -in /etc/crts/cert.csr \
    -CA /etc/crts/cert.ca.crt \
    -CAkey /etc/crts/cert.ca.key \
    -CAcreateserial -out /etc/crts/cert.crt
