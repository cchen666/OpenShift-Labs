# Migration Toolkit for Container

## Installation

1. The MTC operator needs to be installed on both source and destination cluster with the same version
2. After installing the operator, the admin needs to create `Migration Controller` CR on the clusters
3. To access the MTC console, after step 2, check `route` under `openshift-migration` namespace

### Destination Cluster

1. Get the service account token by running

   ```bash

   $ oc get sa migration-controller -n openshift-migration -o yaml
   $ oc get secret migration-controller-dockercfg-XXXXX -o yaml | grep openshift.io/token-secret.value | awk '{print $2}'

   ```

### Replicate Repo

* To Use MCG on ODF

1. Create ObjectBucketClaim on the ODF cluster
2. Retrieve the endpoint and AWS credentials by running `oc describe noobaa -n openshift-storage`
3. On MTC console, create replicate repo by using the information obtained from step 1 and 2

## Migration Plan

1. Create Migration Plan on MTC console
2. Select source namespace and you could edit target namespace name
3. `Stage` or `Cutover` the migration plan to start the migration
