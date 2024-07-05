# WebSocket

## Create WebSocket App

```bash

$ oc apply -f files/deploy.yaml

```

## Use curl to Test the connection

In newer version of OpenShift (4.14), the ingress Pod will check Sec-WebSocket-Key more strictly. Therefore a wrong format of Sec-WebSocket-Key will make the ingress Pod return 400.

```bash
$ curl -v   -H "Connection: Upgrade"   -H "Upgrade: websocket"   -H "Sec-WebSocket-Key: PlzTgNteCiO8KzOEHf0TFQ=="   -H "Sec-WebSocket-Version: 13" http://websocket-demo-test-websocket.apps.cchen414.cchen.work
* Host websocket-demo-test-websocket.apps.cchen414.cchen.work:80 was resolved.
* IPv6: (none)
* IPv4: 10.0.109.183
*   Trying 10.0.109.183:80...
* Connected to websocket-demo-test-websocket.apps.cchen414.cchen.work (10.0.109.183) port 80
> GET / HTTP/1.1
> Host: websocket-demo-test-websocket.apps.cchen414.cchen.work
> User-Agent: curl/8.6.0
> Accept: */*
> Connection: Upgrade
> Upgrade: websocket
> Sec-WebSocket-Key: PlzTgNteCiO8KzOEHf0TFQ==
> Sec-WebSocket-Version: 13
>
< HTTP/1.1 101 Switching Protocols
< upgrade: websocket
< connection: Upgrade
< sec-websocket-accept: nEnAKvDfyg3Udv4gFhAT34G9+Pg=
< set-cookie: 2f42bd96d87baa5617cf4aa795882fd0=cc90e3776110d017d8c6f163d199ab50; path=/; HttpOnly
<
```

## Use wscat to Test the WebSocket App

```bash
$ podman run -t -i fedora:36 /bin/bash
[root@83585d6cd522 /]# dnf install npm
[root@83585d6cd522 /]# npm install -g wscat
[root@83585d6cd522 /]# wscat -c ws://websocket-demo-test-websocket.apps.cchen414.cchen.work
Connected (press CTRL+C to quit)
> this application will return anything that I input
< this application will return anything that I input
```
