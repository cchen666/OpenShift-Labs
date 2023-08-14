# Reset Kibana using ES API

* Get the list of elasticsearch pods

```bash
$ oc get pods -n openshift-logging | grep elasticsearch
```

* Check the Elasticsearch is in health state

```bash
$ oc exec elasticsearch-cdm-6900sppo-3-5bf78b6f6c-k5br7 -c elasticsearch -n openshift-logging -- health
Thu Mar 18 08:37:00 UTC 2021
epoch      timestamp cluster       status node.total node.data shards pri relo init unassign pending_tasks max_task_wait_time active_shards_percent
1616056620 08:37:00  elasticsearch green           3         3    250 125    0    0        0             0                  -                100.0%
```

* Cat the indices

```bash
$ oc exec elasticsearch-cdm-6900sppo-3-5bf78b6f6c-k5br7 -n openshift-logging  -- curl -s --cert /etc/elasticsearch/secret/admin-cert --key /etc/elasticsearch/secret/admin-key --cacert /etc/elasticsearch/secret/admin-ca https://localhost:9200/_cat/indices?v
```

* Delete Kibana

```bash
$ oc exec elasticsearch-cdm-6900sppo-3-5bf78b6f6c-k5br7 -n openshift-logging  -- curl -s --cert /etc/elasticsearch/secret/admin-cert --key /etc/elasticsearch/secret/admin-key --cacert /etc/elasticsearch/secret/admin-ca -XDELETE https://localhost:9200/.kibana*
```

* Restart Kibana

```bash
$ oc delete pod kibana-8d956f7dd-k2dfv -n openshift-logging
```

* Login to Kibana console and initialize

```bash
$ oc get route -n openshift-logging
```

* Another method to run ES command inside ES container

```bash
$ es_util --query="_flush/synced" -XPOST
$ es_util --query=".kibana_1" -XDELETE
$ es_util --query=".security" -XDELETE
$ es_util --query="_flush/synced" -XPOST
```
