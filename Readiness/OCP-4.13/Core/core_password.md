# Configure Core User's Password

## Generate a Password

```bash
$ mkpasswd --method=SHA-512 testpass
```

## Put Password to MC

```bash
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 99-worker-password
spec:
  config:
    ignition:
      version: 3.2.0
    passwd:
      users:
      - name: core
        passwordHash: $6$uyDWbU/DGDQ2WMFm$WEIyfaqt4216TW00.uGQ3qdO/ul1.h0hqoeea4oedAP9ciMXljLwXk6CHdWF7aRv.Hq1qRX25FwMf7kh02spq/
```

## Apply the MC, Login to the Node from Console (SSH doesn't support)
