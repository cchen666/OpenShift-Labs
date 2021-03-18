* Get the list of elasticsearch pods
~~~
$ oc get pods -n openshift-logging | grep elasticsearch
~~~
* Cat the indices
~~~
$ oc exec elasticsearch-cdm-6900sppo-3-5bf78b6f6c-k5br7 -n openshift-logging  -- curl -s --cert /etc/elasticsearch/secret/admin-cert --key /etc/elasticsearch/secret/admin-key --cacert /etc/elasticsearch/secret/admin-ca https://localhost:9200/_cat/indices?v
~~~
* Delete Kibana
~~~
$ oc exec elasticsearch-cdm-6900sppo-3-5bf78b6f6c-k5br7 -n openshift-logging  -- curl -s --cert /etc/elasticsearch/secret/admin-cert --key /etc/elasticsearch/secret/admin-key --cacert /etc/elasticsearch/secret/admin-ca -XDELETE https://localhost:9200/.kibana*
~~~
* Restart kibana
~~~
$ oc delete pod kibana-8d956f7dd-k2dfv -n openshift-logging
~~~
