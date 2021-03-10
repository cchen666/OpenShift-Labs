# Mutual TLS test

## Generate CA cert, server cert, key and client cert, key

~~~bash

$ pip install trustme
$ python cert.py

~~~

## Start the Server

~~~bash

$ go run server.go

~~~

## Access the Server using mtls Way

* The curl needs to specify either `--cacert` to trust server certificate CA,  or `-k` to bypass the certificate verification. The self-signed certificate doesn't work <https://unix.stackexchange.com/questions/451207/how-to-trust-self-signed-certificate-in-curl-command-line>

~~~bash

$ curl --cacert ca.crt --cert client.crt --key client.key  https://localhost:8444/hello
Hello, world!

# Or

$ curl -k  --cert client.crt --key client.key  https://localhost:8444/hello
Hello, world!

# Failure Scenario

$ curl --cert client.crt --key client.key  https://localhost:8444/hello
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.

~~~
