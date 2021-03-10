#!/bin/bash
mkdir -p certs
DOMAIN=$(oc whoami --show-console  | awk -F'apps.' '{print $2}')
CN=frontend-istio-$USERID.apps.$SDOMAIN
echo "Create Root CA and Private Key"
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' \
-keyout certs/example.com.key -out certs/example.com.crt
echo "Create Certificate and Private Key for $CN"
openssl req -out certs/frontend.csr -newkey rsa:2048 -nodes -keyout certs/frontend.key -subj "/CN=${CN}/O=Great Department"
openssl x509 -req -days 365 -CA certs/example.com.crt -CAkey certs/example.com.key -set_serial 0 -in certs/frontend.csr -out certs/frontend.crt
