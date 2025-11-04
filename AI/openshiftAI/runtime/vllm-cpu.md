# Build vllm-cpu Image

<https://developers.redhat.com/articles/2025/06/17/how-run-vllm-cpus-openshift-gpu-free-inference>

## Disable the SELinux

```bash
$ sudo setenforce 0
```

## Build the vllm-cpu Image

```bash

$ git clone https://github.com/vllm-project/vllm
$ cd vllm
$ podman build -t quay.io/rhn_support_cchen/vllm:latest --arch=x86_64 TARGETARCH=amd64 -f docker/Dockerfile.cpu .

$ podman login quay.io
Username: <username>
Password: <password>
$ podman push quay.io/rhn_support_cchen/vllm:latest

```
