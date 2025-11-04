# Configure Model Registry

## Install the HPP Operator to configure the storage

<https://github.com/kubevirt/hostpath-provisioner-operator>

## Create mariadb instance under rhoai-model-registries namespace

```bash
$ oc apply -f files/mariadb.yaml -n rhoai-model-registries
```

## Create minio

```
$ oc new-project utilities
$ oc apply -f files/minio.yaml -n utilities
```