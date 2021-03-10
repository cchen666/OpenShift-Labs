# Install OpenShift on OpenStack IPI

## Pre Install Configuration

1. Configure credentials

   * Download rc file from webconsole Project -> API Access -> Download OpenStack RC File,

   * Source the RC file with kerberos + token
   * Create application credentials with

    ```bash
    $ openstack application credential create cchen-osp | tee ~/.config/openstack/cchen-osp.app-cred.txt
    ```

   * Edit `~/.config/openstack/clouds.yaml`

    ```yaml
    clouds:
      openstack:
        auth_type: "v3applicationcredential"
        auth:
          auth_url: https://api.rhos-01.prod.psi.rdu2.redhat.com:13000
          application_credential_id: f3aa492970f44f1f81b140e3ce060419
          application_credential_secret: 1JslgsLNXqVfYWpM-3xcO8jl2YMXiEuaz_WKdkwc5HpkZc8fqSHO0QoA
    ```

    * Test the credentials

    ```bash
    $ openstack --os-cloud openstack server list
    ```

2. Create Floating IPs for API and Ingress

    ```bash

    $ openstack floating ip create --description "api.multi-osp.cchen.work" shared_net_3
    $ openstack floating ip create --description "apps.multi-osp.cchen.work" shared_net_3
    $ openstack floating ip list --long -c 'Floating IP Address' -c Description
    +---------------------+-----------------------------------+
    | Floating IP Address | Description                       |
    +---------------------+-----------------------------------+
    | 10.0.111.112        | api.multi-osp.cchen.work          |
    | 10.0.109.186        | apps.multi-osp.cchen.work         |
    +---------------------+-----------------------------------+

    $ openstack floating ip set --tag reserve 10.0.111.112
    $ openstack floating ip set --tag reserve 10.0.109.186

    ```

3. Make the floating IPs above resolvable globally. Recommend to add it to your own domain name managed by either name.com or other public cloud services such as AWS or AliCloud

4. Create Security Group

    ```bash
    $ openstack security group create OCP  --description "allow 6443 443 80 22"

    $ openstack security group rule create --proto tcp --remote-ip 0.0.0.0/0 --dst-port 6443 OCP
    $ openstack security group rule create --proto tcp --remote-ip 0.0.0.0/0 --dst-port 443 OCP
    $ openstack security group rule create --proto tcp --remote-ip 0.0.0.0/0 --dst-port 80 OCP
    $ openstack security group rule create --proto tcp --remote-ip 0.0.0.0/0 --dst-port 22 OCP

    $ openstack security group list -c ID -c Name -c Description
    +--------------------------------------+------------------------+--------------------------------+
    | ID                                   | Name                   | Description                    |
    +--------------------------------------+------------------------+--------------------------------+
    | 604df802-aa38-4cd2-a65d-9af8484f91b5 | OCP                    | allow 6443 443 80 22           |
    | 7ba1187e-4433-4eba-9a81-29ef3dcf190a | all rules              | all rules                      |
    | b029f012-294f-431f-9f95-cf94eac90743 | ssh                    |                                |
    | e18ec1e0-3227-4de1-9cc2-e050928249e3 | default                | Default security group         |
    +--------------------------------------+------------------------+--------------------------------+
    ```

5. Confirm Available Flavors

    ```bash

    $ openstack flavor list

    ```

## Fill in the install-config.yaml

```bash

$ cat files/install-config.yaml
apiVersion: v1
baseDomain: cchen.work # A publicly accessible domain name in name.com
controlPlane:
  name: master
  platform:
    openstack:
      type: m1.xlarge
      additionalSecurityGroupIDs:
      - 43b41f6d-585d-459b-ad87-2eb18bb4e930 # OCP Security Group
#      rootVolume: # If you would like to use Cinder volume instead of ephermeral disks
#        size: 80
#        type: tripleo
  replicas: 3
compute:
- name: worker
  platform:
    openstack:
      type: m1.xlarge
      additionalSecurityGroupIDs:
      - 43b41f6d-585d-459b-ad87-2eb18bb4e930 # OCP Security Group
#      rootVolume:
#        size: 80
#        type: tripleo
  replicas: 2
metadata:
  name: multi-osp
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: 192.168.0.0/24 # Need to change from 10.0.0.0/16 due to overlapped subnet of RH lab
  serviceNetwork:
  - 172.30.0.0/16
  networkType: OVNKubernetes
platform:
  openstack:
    cloud: psi
    externalNetwork: provider_net_shared_3 # Pre-configured external Network
    computeFlavor: m1.xlarge
    apiFloatingIP: 10.0.111.112            # API Floating IP we created before
    ingressFloatingIP: 10.0.109.186        # Ingress Floating IP we created before
pullSecret: '{"auths": ...}'
sshKey: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDTPFzWldumzMj3l5AndYGxTyUQxUi1cdUTHsUnwjMfcZXHc3dH9G8y1HUkfs4g3+gwLX/FmGsVWz6/61Y/+RyPJg5wI8XyP0QEYCaJ8BDiJw3rlMwrbBdIYBDwvdaMn655IM7qYgQbaXNIYKVRgaRStA2DzZqKJkdkLRW0JxA2nrRhKTLqtGzQXMYh897Aur5lt1NgafZYZbBy66LozCxe3c22avYpY7f3Of8zinJo4ZXQufHa0jQcL+6j/TpP0PYkK4R2/7UqWHP9+NREr5iKqBm3H9Ddc7ZtroKV9AaIckVyZcC8s+RlaHjI2PuSl+OBU2FnSHZbfnehSIRFhLr4O8MHy1jw3Ki/eR+V/2kDHIDHIi+1d7TTwBZMjMjXn8lffFezYze67bV+dHe+DonbZGJqXqA8+df8A3jMcl5/GQ1l5giNu6xUvQU0exH4Y2YurF7wcTy0dYJ60kM40l6QbXzNC00NShd8s5ixo8sv3rqpEpUq/JWNuZ5QNoA0eik= cchen@Chens-MacBook-Pro.local
```

## Launch the Installation

```bash

$ mkdir install
$ cp install-config.yaml install
$ ./openshift-install create cluster --dir=install
INFO Credentials loaded from file "/Users/cchen/.config/openstack/clouds.yaml"
INFO Consuming Install Config from target directory
INFO Obtaining RHCOS image file from 'https://rhcos.mirror.openshift.com/art/storage/releases/rhcos-4.11/411.86.202210041459-0/x86_64/rhcos-411.86.202210041459-0-openstack.x86_64.qcow2.gz?sha256=b00c23ccfbff9491bb95a74449af6d6a367727b142bb9447157dd03c895a0e9f'
INFO The file was found in cache: /Users/cchen/Library/Caches/openshift-installer/image_cache/rhcos-411.86.202210041459-0-openstack.x86_64.qcow2. Reusing...
INFO Creating infrastructure resources...
INFO Waiting up to 20m0s (until 10:34AM) for the Kubernetes API at https://api.multi-osp.cchen.work:6443...
INFO API v1.24.6+5157800 up
INFO Waiting up to 30m0s (until 10:46AM) for bootstrapping to complete...
INFO Destroying the bootstrap resources...
INFO Waiting up to 40m0s (until 11:13AM) for the cluster at https://api.multi-osp.cchen.work:6443 to initialize...
INFO Install complete!
INFO To access the cluster as the system:admin user when using 'oc', run
INFO     export KUBECONFIG=/Users/cchen/Code/ocp_install/osp/install/auth/kubeconfig
INFO Access the OpenShift web-console here: https://console-openshift-console.apps.multi-osp.cchen.work
INFO Login to the console with user: "kubeadmin", and password: "XXXXXX-XXXXXX-XXXXXX"
INFO Time elapsed: 1h1m56s
```

## Check the Cluster

```bash

oc get co
NAME                                       VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE   MESSAGE
authentication                             4.11.14   True        False         False      4m56s
baremetal                                  4.11.14   True        False         False      24m
cloud-controller-manager                   4.11.14   True        False         False      27m
cloud-credential                           4.11.14   True        False         False      28m
cluster-autoscaler                         4.11.14   True        False         False      24m
config-operator                            4.11.14   True        False         False      25m
console                                    4.11.14   True        False         False      9m11s
csi-snapshot-controller                    4.11.14   True        False         False      25m
dns                                        4.11.14   True        False         False      24m
etcd                                       4.11.14   True        False         False      22m
image-registry                             4.11.14   True        False         False      11m
ingress                                    4.11.14   True        False         False      11m
insights                                   4.11.14   True        False         False      18m
kube-apiserver                             4.11.14   True        False         False      20m
kube-controller-manager                    4.11.14   True        False         False      21m
kube-scheduler                             4.11.14   True        False         False      20m
kube-storage-version-migrator              4.11.14   True        False         False      25m
machine-api                                4.11.14   True        False         False      21m
machine-approver                           4.11.14   True        False         False      25m
machine-config                             4.11.14   True        False         False      23m
marketplace                                4.11.14   True        False         False      24m
monitoring                                 4.11.14   True        False         False      9m59s
network                                    4.11.14   True        False         False      24m
node-tuning                                4.11.14   True        False         False      24m
openshift-apiserver                        4.11.14   True        False         False      17m
openshift-controller-manager               4.11.14   True        False         False      20m
openshift-samples                          4.11.14   True        False         False      14m
operator-lifecycle-manager                 4.11.14   True        False         False      25m
operator-lifecycle-manager-catalog         4.11.14   True        False         False      25m
operator-lifecycle-manager-packageserver   4.11.14   True        False         False      18m
service-ca                                 4.11.14   True        False         False      25m
storage                                    4.11.14   True        False         False      19m
```

## Performance

1. Check ETCD Performance

* When Storage backend is Ceph:

    ```bash

    $ oc get pods
    NAME                                         READY   STATUS      RESTARTS   AGE
    etcd-guard-multi-osp-dmbjv-master-0          1/1     Running     0          9h
    etcd-guard-multi-osp-dmbjv-master-1          1/1     Running     0          9h
    etcd-guard-multi-osp-dmbjv-master-2          1/1     Running     0          9h
    etcd-multi-osp-dmbjv-master-0                5/5     Running     0          9h
    etcd-multi-osp-dmbjv-master-1                5/5     Running     0          9h
    etcd-multi-osp-dmbjv-master-2                5/5     Running     0          9h
    installer-4-multi-osp-dmbjv-master-0         0/1     Completed   0          9h
    installer-6-multi-osp-dmbjv-master-0         0/1     Completed   0          9h
    installer-6-multi-osp-dmbjv-master-2         0/1     Completed   0          9h
    installer-7-multi-osp-dmbjv-master-0         0/1     Completed   0          9h
    installer-7-multi-osp-dmbjv-master-1         0/1     Completed   0          9h
    installer-7-multi-osp-dmbjv-master-2         0/1     Completed   0          9h
    installer-8-multi-osp-dmbjv-master-0         0/1     Completed   0          9h
    installer-8-multi-osp-dmbjv-master-1         0/1     Completed   0          9h
    installer-8-multi-osp-dmbjv-master-2         0/1     Completed   0          9h
    revision-pruner-7-multi-osp-dmbjv-master-0   0/1     Completed   0          9h
    revision-pruner-7-multi-osp-dmbjv-master-1   0/1     Completed   0          9h
    revision-pruner-7-multi-osp-dmbjv-master-2   0/1     Completed   0          9h
    revision-pruner-8-multi-osp-dmbjv-master-0   0/1     Completed   0          9h
    revision-pruner-8-multi-osp-dmbjv-master-1   0/1     Completed   0          9h
    revision-pruner-8-multi-osp-dmbjv-master-2   0/1     Completed   0          9h

    $ for i in `oc get pods | grep etcd-multi | awk '{print $1}'`; do oc logs $i -c etcd | grep 'took too long' | wc -l; done
    3356
    5344
    5250

    ```

* When Storage Backend type is tripleo

    ```bash
    oc get pods -n openshift-etcd
    NAME                                         READY   STATUS      RESTARTS   AGE
    etcd-guard-multi-osp-5khjg-master-0          1/1     Running     0          8h
    etcd-guard-multi-osp-5khjg-master-1          1/1     Running     0          8h
    etcd-guard-multi-osp-5khjg-master-2          1/1     Running     0          9h
    etcd-multi-osp-5khjg-master-0                5/5     Running     0          8h
    etcd-multi-osp-5khjg-master-1                5/5     Running     0          8h
    etcd-multi-osp-5khjg-master-2                5/5     Running     0          8h
    installer-5-multi-osp-5khjg-master-0         0/1     Completed   0          8h
    installer-5-multi-osp-5khjg-master-1         0/1     Completed   0          8h
    installer-7-multi-osp-5khjg-master-0         0/1     Completed   0          8h
    installer-7-multi-osp-5khjg-master-1         0/1     Completed   0          8h
    installer-7-multi-osp-5khjg-master-2         0/1     Completed   0          8h
    installer-8-multi-osp-5khjg-master-0         0/1     Completed   0          8h
    installer-8-multi-osp-5khjg-master-1         0/1     Completed   0          8h
    installer-8-multi-osp-5khjg-master-2         0/1     Completed   0          8h
    revision-pruner-7-multi-osp-5khjg-master-0   0/1     Completed   0          8h
    revision-pruner-7-multi-osp-5khjg-master-1   0/1     Completed   0          8h
    revision-pruner-7-multi-osp-5khjg-master-2   0/1     Completed   0          8h
    revision-pruner-8-multi-osp-5khjg-master-0   0/1     Completed   0          8h
    revision-pruner-8-multi-osp-5khjg-master-1   0/1     Completed   0          8h
    revision-pruner-8-multi-osp-5khjg-master-2   0/1     Completed   0          8h

    $ for i in `oc get pods | grep etcd-multi | awk '{print $1}'`; do oc logs $i -c etcd | grep 'took too long' | wc -l; done
    2855
    2495
    2948
    ```

    Conclusion: Though Ceph is SSD based, the default local volume is better than distributed storage for ETCD.

## Reference

<https://source.redhat.com/groups/public/cee_labs/labs_wiki/ocp_4x_installation_on_psi>
