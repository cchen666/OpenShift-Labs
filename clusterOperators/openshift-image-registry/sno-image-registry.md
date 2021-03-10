# SNO Image Registry Configuration

## Install Local Storage Operator

## Create PV/VG/LV on SNO Node

~~~bash

$ pvcreate /dev/sdb
$ vgcreate ocp-vg /dev/sdb
$ lvcreate -L 200G -n ocp-lv-image-registry ocp-vg
$ lvcreate -L 100G -n ocp-lv-1
$ lvcreate -L 100G -n ocp-lv-2
$ lvcreate -L 100G -n ocp-lv-3

~~~

## Create LocalVolume CR

~~~bash

$ oc apply -f files/localvolume.yaml -n openshift-local-storage

$ oc get pv
NAME                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                                         STORAGECLASS   REASON   AGE
local-pv-49c4ebd1   100Gi      RWO            Delete           Available                                                 mysc                    42m
local-pv-5c5a8a98   100Gi      RWO            Delete           Available                                                 mysc                    42m
local-pv-908cb105   200Gi      RWO            Delete           Available                                    mysc                    6m55s
local-pv-f89162a    100Gi      RWO            Delete           Available                                                 mysc                    42m
~~~

## Create PVC

~~~bash

$ oc apply -f files/pvc-image-registry.yaml -n openshift-image-registry

~~~

## Edit ImageRegistry Configuration

~~~bash

$ oc edit configs.imageregistry
spec:
  httpSecret: 126e3f55ac8c82791bd4e0e7a7b951615cf7143e832e52f4d8c442f431dc64c1edb85882961e8218b0434d4313b944bfc04fb6ec46906f65e6c066a819d65752
  logLevel: Normal
  managementState: Managed          <========
  observedConfig: null
  operatorLogLevel: Normal
  proxy: {}
  replicas: 1
  requests:
    read:
      maxWaitInQueue: 0s
    write:
      maxWaitInQueue: 0s
  rolloutStrategy: Recreate         <========
  storage:
    managementState: Managed
    pvc:                            <========
      claim: pvc-image-registry     <========
~~~
