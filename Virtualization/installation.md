# OpenShift Virtualization

## Installation

~~~bash
$ oc apply -f files/operator.yaml
$ oc apply -f files/hyperConverged.yaml
~~~

## NodePlacement

1. Specify Subscription spec.config.nodeSelector for Operators
2. Specify spec.infra and spec.workloads for hyperConverged CR
