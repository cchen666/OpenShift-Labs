# API for Elastic Search

<https://www.elastic.co/guide/en/elasticsearch/reference/6.8/cat.html>

## Common Usage

* ?v - Add title of output

~~~bash

GET /_cat/master?v

sh-4.4$ es_util --query=_cat/master?v
id                     host         ip           node
8uYT4jr9TYyS6jbnaUk2Ug 10.129.3.129 10.129.3.129 elasticsearch-cdm-br1yl6pa-2

sh-4.4$ es_util --query=_cat/nodes?v
ip           heap.percent ram.percent cpu load_1m load_5m load_15m node.role master name
10.128.2.51            36         100   6    1.01    1.27     1.22 mdi       -      elasticsearch-cdm-br1yl6pa-3
10.129.3.129           57          99   8    0.76    1.03     1.35 mdi       *      elasticsearch-cdm-br1yl6pa-2
10.131.0.133           39          98   7    2.20    1.92     2.17 mdi       -      elasticsearch-cdm-br1yl6pa-1

~~~

* ?h - Headers

~~~bash

$ es_util --query=_cat/master?v\&h=ip,node
ip           node
10.129.3.129 elasticsearch-cdm-br1yl6pa-2

~~~

* ?help - Check possible columns

~~~bash
$ es_util --query=_cat/nodes?help
id                           | id,nodeId                      | unique node id
pid                          | p                              | process id
ip                           | i                              | ip address
port                         | po                             | bound transport port
http_address                 | http                           | bound http address
version                      | v                              | es version
flavor                       | f                              | es distribution flavor
type                         | t                              | es distribution type
build                        | b                              | es build hash
jdk                          | j                              | jdk version
disk.total                   | dt,diskTotal                   | total disk space
disk.used                    | du,diskUsed                    | used disk space
disk.avail                   | d,da,disk,diskAvail            | available disk space
disk.used_percent            | dup,diskUsedPercent            | used disk space percentage
heap.current                 | hc,heapCurrent                 | used heap
heap.percent                 | hp,heapPercent                 | used heap ratio
heap.max                     | hm,heapMax                     | max configured heap
ram.current                  | rc,ramCurrent                  | used machine memory

$ es_util --query=_cat/nodes?v\&h=ip,uptime,ram.current
ip           uptime ram.current
10.128.2.51    3.3d       7.9gb
10.129.3.129   3.3d       7.9gb
10.131.0.133   3.3d       7.8gb

~~~

## Indices

~~~bash
$ oc rsh elasticsearch-cdm-br1yl6pa-3-86b76c6b98-ldzm5

# We can tell quickly how many shards make up an index, the number of replica, the number of docs, 
# deleted docs, primary store size, and total store size (all shards including replicas). 

sh-4.4$ es_util --query=_cat/indices?v
health status index        uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   app-000067   ib4UasDWTWyHVThAwP6_Og   3   1       3885            0        5mb          2.4mb
green  open   app-000061   03crHSZQRNOijJARhH4ZXA   3   1       2979            0      3.9mb          1.9mb
green  open   infra-000010 uRvcqZAXRKi9lISk8CihEQ   3   1    1343485            0      2.3gb            1gb
green  open   app-000064   qlIT1Ux5Tqyf-7fvwgc4-w   3   1       3732            0      4.8mb          2.4mb
green  open   audit-000006 GszTS0ybSw6qFaJB7DgCuw   3   1          0            0      1.5kb           783b
green  open   audit-000004 _OSxgKfrQtuqfVA-O7QE8Q   3   1          0            0      1.5kb           783b
green  open   app-000051   YdC2g9ruSL2VIVvGQ9IRlA   3   1       3596            0      4.7mb          2.4mb
green  open   app-000060   npASHNtWQ7y1QY1U_Olj7g   3   1       3861            0      5.1mb          2.5mb
green  open   app-000055   6NSbM9aESyy3a-7vsGG7eA   3   1       3602            0      4.7mb          2.3mb
~~~

## ElasticSearch Version

~~~bash

$ $ es_util --query=/
{
  "name" : "elasticsearch-cdm-br1yl6pa-3",
  "cluster_name" : "elasticsearch",
  "cluster_uuid" : "i78x6FKyTEuVOMOKDPxChg",
  "version" : {
    "number" : "6.8.1",
    "build_flavor" : "oss",
    "build_type" : "zip",
    "build_hash" : "97a1f4c",
    "build_date" : "2021-04-14T17:01:06.151131Z",
    "build_snapshot" : false,
    "lucene_version" : "7.7.0",
    "minimum_wire_compatibility_version" : "5.6.0",
    "minimum_index_compatibility_version" : "5.0.0"
  },
  "tagline" : "You Know, for Search"
}
~~~

## Cluster Health Status

~~~bash

$ es_util --query=_cluster/health?pretty
{
  "cluster_name" : "elasticsearch",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 3,
  "number_of_data_nodes" : 3,
  "active_primary_shards" : 128,
  "active_shards" : 256,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 100.0
}

# Let's dig more about active_primary_shards: 128.
# 128 = SUM(shard number of every index ). In this example, we have totally 44 indices and among them
# 42 indices got 3 Primary Shards while 2 of 44 indices got only 1 Shard. So we have (44-2) * 3 + 2 * 1 = 128.

# active_shards: 256. Because for every Indices we have Replica = 1, so totaly shards number = 128 * 2 = 256.

~~~

## Memory Usage sorted by Index

~~~bash

# Pay attention to the '&' we need to add slash in front of it

sh-4.4$ es_util --query=_cat/indices?v\&h=i,tm\&s=tm:desc
i                 tm
infra-000010  25.6mb
infra-000001  20.7mb
infra-000003   5.7mb
infra-000004   5.6mb
infra-000008   5.5mb
infra-000007   5.5mb
infra-000005   5.5mb
infra-000006   5.5mb
infra-000002   5.5mb
infra-000009   5.4mb
app-000052   336.2kb
app-000060   320.3kb
app-000065   316.8kb
app-000055   315.8kb
app-000056   315.7kb

~~~
