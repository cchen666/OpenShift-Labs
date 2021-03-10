# CoreDNS

## Troubleshooting

~~~bash

# Merge all the request to a single node so that it is easier to check logs

$ oc label node XXXXXX test-dns=true

$ oc -n openshift-dns edit dns.operator
<Snip>
spec:
  nodePlacement:
    nodeSelector:
      test-dns: "true"
~~~
