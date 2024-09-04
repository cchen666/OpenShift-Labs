# EgressIP

## Label the Nodes

```bash
$ for i in cchen414-fzb7j-worker-0-nvmxn cchen414-fzb7j-worker-0-qrmvn;
do
  oc label node $i k8s.ovn.org/egress-assignable=true
done

```

## Label the namespace

```bash
$ oc new-project test-03895290
$ oc label namespace test-03895290 egress-enabled=true
```

## Create egressIP

```yaml
apiVersion: k8s.ovn.org/v1
kind: EgressIP
metadata:
  name: egressip-sample
spec:
  egressIPs:
  - 192.168.1.111
  - 192.168.1.112
  namespaceSelector:
    matchLabels:
      egress-enabled: "true"
```

## Test

In the pod, run the following command to test the egressIP, where 192.168.1.106 is the IP address of an external httpd server.

```bash
sh-4.4# while true; do echo -n "$(date '+%Y-%m-%d %H:%M:%S') - "; curl --connect-time 1 -m 2 -s 192.168.1.106 -w "response: %{response_code}\n" -o /dev/null ; sleep 1; done
```

If we shutdown the node which holds the egressIP, the curl command will fail.

The expected output which shows the failover has been recorded in an internal [video](https://redhat-internal.slack.com/archives/C03R2LLGR9A/p1725415903198999)
