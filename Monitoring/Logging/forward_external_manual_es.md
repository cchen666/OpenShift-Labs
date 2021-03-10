# Forward to External ES

## Create ES yum repo

~~~bash

$ cat /etc/yum.repos.d/elastic.repo

[elasticsearch]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=0
autorefresh=1
type=rpm-md

$ yum install --enablerepo=elasticsearch elasticsearch

~~~

## ES Configuration

~~~bash

$ hostnamectl set-hostname node-1

$ grep -v ^# /etc/elasticsearch/elasticsearch.yml
cluster.name: my-application
node.name: node-1
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 10.0.8.230
http.port: 9200
cluster.initial_master_nodes: ["node-1"]

$ systemctl start elasticsearch

~~~

## Create Kibana yum repo

~~~bash

$ cat /etc/yum.repos.d/kibana.repo
[kibana-7.x]
name=Kibana repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md

$ yum install kibana

~~~

## Kibana Configuration

~~~bash

$ grep -v ^# /etc/kibana/kibana.yml | grep -v ^$
server.host: "10.0.8.230"
elasticsearch.hosts: ["http://10.0.8.230:9200"]

$ systemctl start kibana

~~~

## Test

~~~bash

# Configure the CLF as files/clf_es.yaml first

$ curl 10.0.8.230:9200/_cat/health?v
epoch      timestamp cluster        status node.total node.data shards pri relo init unassign pending_tasks max_task_wait_time active_shards_percent
1645624744 13:59:04  my-application yellow          1         1     11  11    0    0        1             0                  -                 91.7%

$ curl 10.0.8.230:9200/_cat/indices?v # The application index is created and called app-write in this example
health status index                           uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   .geoip_databases                ifuWq6i4RamzbgsfPYL-Pg   1   0         41           41     41.3mb         41.3mb
green  open   .kibana_7.17.0_001              l6RVf0bARTG47wdrxKEKJw   1   0        278            1      4.8mb          4.8mb
green  open   .apm-custom-link                LaKJzUfoQkqglOB7S7BClA   1   0          0            0       226b           226b
green  open   .apm-agent-configuration        3tOun5kTQxihKmHFSY2kHw   1   0          0            0       226b           226b
green  open   .async-search                   qBr6_6o6Tt2G7SAFO_mofQ   1   0          0            0       252b           252b
yellow open   app-write                       UurIn0SSSpe0WgXOc_hC9w   1   1    1553905            0        1gb            1gb
green  open   .kibana_task_manager_7.17.0_001 Z3chVpPgQSCSkAt4__MoOQ   1   0         17           96     13.9mb         13.9mb
green  open   .tasks                          xDTJgpzjRY-V0lS6TS5CsQ   1   0          2            0     13.6kb         13.6kb

$ netstat -tunlp|grep 5601 # Kibana by default listens 5601
tcp        0      0 10.0.8.230:5601         0.0.0.0:*               LISTEN      9027/node

~~~
