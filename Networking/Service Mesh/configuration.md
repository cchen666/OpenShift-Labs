# Configuration

## Enable Access Log in istio-prxoy

<https://access.redhat.com/solutions/5127991>

~~~bash

oc patch smcp basic -n istio-system --type merge -p '{"spec":{"proxy":{"accessLogging":{"file":{"name":"/dev/stdout"}}}}}'

~~~

## Change outboundTrafficPolicy

~~~bash

$ oc edit smcp -n istio-system

spec:
  proxy:
    networking:
      trafficControl:
        outbound:
          policy: REGISTRY_ONLY

~~~
