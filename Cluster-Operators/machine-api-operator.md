# Machine-api

## Troubleshooting

* 1. oc scale doesn't create new node SFDC:02603655

~~~bash
# Check the machine-controller log
namespaces/machine-api-operator/pods/machine-controller/logs/
# Quota exceeded in infra layer
~~~
