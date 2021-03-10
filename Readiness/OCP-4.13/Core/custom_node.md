# Custom Nodes

## Get Node Image

```bash
$ oc adm release info --image-for=rhel-coreos-8
```

## Customize Node Image

```bash
FROM quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:cbb1fe5c5a4312a2a14aaa2b1a56ab68e3a00710ddcb8a5403e5c75df1ffb4db # Should be CoreOS image
COPY cri-o-1.25.2-15.rhaos4.12.git3e4b64e.el8.x86_64.rpm .
RUN rpm-ostree override replace cri-o-1.25.2-15.rhaos4.12.git3e4b64e.el8.x86_64.rpm && \
    ostree container commit
```

## Build and Push the Customized Image to Registry

```bash
$ podman build -t .
$ podman push XXX
```

## Create MC

```bash
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: worker-extensions
spec:
  osImageURL: <Customized Image URL>
```
