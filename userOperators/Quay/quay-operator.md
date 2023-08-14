# Deploy Quay by Operator

## Deploy Object Storage in Pre-deployment phase

1. Install OpenShift Container Storage Operator

2. $ oc apply -f files/noobaa.yaml -n openshift-storage

3. $ oc apply -f noobaa-pv-backing-store.yaml

4. $ oc patch bucketclass noobaa-default-bucket-class --patch '{"spec":{"placementPolicy":{"tiers":[{"backingStores":["noobaa-pv-backing-store"]}]}}}' --type merge -n openshift-storage

## Deploy Quay CR

```bash

$ oc create secret generic --from-file config.yaml=./files/config.yaml init-config-bundle-secret

$ oc create -f files/quayregistry.yaml

```

## Create quayadmin password

```bash
$  curl -X POST -k  https://example-registry-quay-quay-enterprise.apps.docs.quayteam.org/api/v1/user/initialize --header 'Content-Type: application/json' --data '{ "username": "quayadmin", "password":"<your password>", "email": "quayadmin@example.com", "access_token": true}'

```

## Test

```bash

# podman images
REPOSITORY                                                                                 TAG     IMAGE ID       CREATED        SIZE
localhost/testcase                                                                         8.5.1   92f641dc8eeb   7 weeks ago    414 MB
localhost/testcase                                                                         8.5     4f463baa747c   7 weeks ago    413 MB
registry.access.redhat.com/ubi8/ubi                                                        8.5     cc0656847854   2 months ago   235 MB

$ podman tag localhost/testcase:8.5 example-registry-quay-quay-enterprise.apps.mycluster.nancyge.com/gcg-shift/pub/test-ping:1.0

$ podman   push example-registry-quay-quay-enterprise.apps.mycluster.nancyge.com/gcg-shift/pub/test-ping:1.0 --creds 'quayadmin:<password>'
Getting image source signatures
Copying blob 303e7cb30bcc done
Copying blob 0d3f22d60daf done
Copying blob 0488bd866f64 done
Copying config 4f463baa74 done
Writing manifest to image destination
Storing signatures

## Download quay pull secret from the WebUI and add it to pod.yaml

<https://example-registry-quay-quay-enterprise.apps.mycluster.nancyge.com/user/quayadmin?tab=settings> Docker CLI Password -> Kubernetes Secrets -> View and Download the secret.yaml

$ oc apply -f files/pod.yaml
$ oc get pods -n test-quay-image
NAME        READY   STATUS    RESTARTS   AGE
test-quay   1/1     Running   10         10h

$ oc logs test-quay -n test-quay-image
The app is running!

$ oc get pv | grep noobaa
pvc-82554c07-1ef6-4df8-9956-1953a0d01f22   300Gi      RWO            Delete           Bound    openshift-storage/noobaa-pv-backing-store-noobaa-pvc-66e12faa      gp2                     12h
pvc-e3bc1c8e-53b3-4abf-9c4d-72ff7c9ac496   300Gi      RWO            Delete           Bound    openshift-storage/noobaa-pv-backing-store-noobaa-pvc-3cd9b132      gp2                     12h
pvc-fb0d4aab-6f99-4be0-a405-08ef6ed0430f   50Gi       RWO            Delete           Bound    openshift-storage/db-noobaa-db-pg-0
```
