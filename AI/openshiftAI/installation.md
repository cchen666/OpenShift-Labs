# Installation of OpenShift AI

## Install the cluster

## Install the dependant operators

### NFD

### GPU Operator

### Pipeline

### ServiceMesh

### Serverless

## An identity provider configured for OpenShift Container Platform and kubeadmin is not allowed

## DSC CR

Firstly create an empty DSC CR, with every component's managementState leaving Removed

## DSC Initialization

Create DSC Init CR. Make sure the serviceMesh managementState is Managed

```yaml
 serviceMesh:
   controlPlane:
     metricsCollection: Istio
     name: data-science-smcp
     namespace: istio-system
   managementState: Managed
```

## Configure DSC CR

Make sure kserve is enabled

```yaml
spec:
 components:
   kserve:
     managementState: Managed
     defaultDeploymentMode: Serverless
     RawDeploymentServiceConfig: Headed
     serving:
       ingressGateway:
         certificate:
           secretName: knative-serving-cert
           type: OpenshiftDefaultIngress
       managementState: Managed
       name: knative-serving
```

After saving the DSC, confirm kserve is started

```bash

$ oc get pods -n redhat-ods-applications
NAME                                        READY   STATUS    RESTARTS   AGE
kserve-controller-manager-6f6959d8f-jlf7c   1/1     Running   0          3m39s
odh-model-controller-649b65b45b-nqrxd       1/1     Running   0          3m42s

```

