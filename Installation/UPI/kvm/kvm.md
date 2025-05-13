# OpenShift on KVM for Baremetal UPI test

<https://github.com/kazuhisya/openshift-ansible-kvm>

## Download from git

```bash
$ yum install ansible-core git -y
$ ansible-galaxy collection install ansible.posix
$ ansible-galaxy collection install community.general
$ ansible-galaxy collection install community.libvirt

$ git clone https://github.com/kazuhisya/openshift-ansible-kvm.git
```

## Configuration

1. Change the number of master node (by default it is 3).
   To change the master node from 3 to 1, edit the file

    ```bash

    $ vi vars/vm_setting.yml
    <snip>
    master:
      - name: master-0
        ip: 172.16.0.101
        mac: "02"
        etcd_id: 0
    #  - name: master-1
    #    ip: 172.16.0.102
    #    mac: "03"
    #    etcd_id: 1
    #  - name: master-2
    #    ip: 172.16.0.103
    #    mac: "04"
    #    etcd_id: 2
    #  Worker VMs
    ```

2. Change the values, refer to files/config.yml
3. Change the inventory, refer to files/hosts

## Installation

```bash
$ ansible-playbook ./main.yml
```

## Access the env through CLI

In my case I am using RHEL8 kvm host and OCP 4.18 oc is based on RHEL9. So I have to use podman container to run the oc. In my case I put all the openshift yamls under /root/ocp. When applying the yamls, I have to use the full path of the yaml file, like `oc apply -f /root/ocp/metallb/metallb.yaml`, otherwise the oc will complain no such file.

```bash
$ alias oc='podman run --rm -it -v ${HOME}/ocp:/root/ocp:Z -v ${HOME}/.kube:/root/.kube:Z registry.redhat.io/openshift4/ose-cli-rhel9:v4.18.0-202503210101.p0.geb9bc9b.assembly.stream.el9 oc'
```

## Access the env through web console

```bash

# In your workstation or laptop, run the following command. This command will hang to intiiate a ssh tunnel form your workstation to the KVM host
$ ssh root@<KVM Host> -ND 127.0.0.1:8888

```

To verify that the ssh tunnel is correctly set

```bash

$ curl --socks5 127.0.0.1:8888 https://console-openshift-console.apps.test.lab.local -k

```

Then In your browswer, configure the VPN to use SOCKS5 127.0.0.1 8888 port. In the workstation/laptop, add the KVM host IP resolution in the /etc/hosts

```bash
$ cat /etc/hosts
10.72.36.88 console-openshift-console.apps.test.lab.local oauth-openshift.apps.test.lab.local

```
