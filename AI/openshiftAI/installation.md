# Installation of OpenShift AI

## Install the cluster

## Install the dependant operators

### NFD

### GPU Operator

### Pipeline

### ServiceMesh

### Serverless

## An identity provider configured for OpenShift Container Platform and kubeadmin is not allowed

<https://examples.openshift.pub/cluster-configuration/authentication/redhat-sso/>

## DSC CR

Firstly create an empty DSC CR, with every component's managementState leaving Removed

## Create DSC CR

```yaml
spec:
  components:
    codeflare:
      managementState: Managed
    dashboard:
      managementState: Managed
    datasciencepipelines:
      argoWorkflowsControllers:
        managementState: Managed
      managementState: Managed
    feastoperator:
      managementState: Removed
    kserve:
      managementState: Managed
      nim:
        managementState: Managed
      rawDeploymentServiceConfig: Headless
      serving:
        ingressGateway:
          certificate:
            type: OpenshiftDefaultIngress
        managementState: Managed
        name: knative-serving
    kueue:
      defaultClusterQueueName: default
      defaultLocalQueueName: default
      managementState: Managed
    llamastackoperator:
      managementState: Removed
    modelmeshserving:
      managementState: Managed
    modelregistry:
      managementState: Managed
      registriesNamespace: rhoai-model-registries
    ray:
      managementState: Managed
    trainingoperator:
      managementState: Managed
    trustyai:
      eval:
        lmeval:
          permitCodeExecution: deny
          permitOnline: deny
      managementState: Managed
    workbenches:
      managementState: Managed
      workbenchNamespace: rhods-notebooks
```

