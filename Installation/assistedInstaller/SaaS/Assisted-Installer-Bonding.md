# Deploying Cluster Using Bonding Interface through AI

## API Method

### Get Token

~~~bash

# Get Offline Access Token from here https://console.redhat.com/openshift/token

$ OFFLINE_ACCESS_TOKEN=<your offline token>

$ export TOKEN=$(curl \
--silent \
--data-urlencode "grant_type=refresh_token" \
--data-urlencode "client_id=cloud-services" \
--data-urlencode "refresh_token=${OFFLINE_ACCESS_TOKEN}" \
https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token | \
jq -r .access_token)

~~~

### Create nmstate network yaml file

~~~bash

# Get server-[abc].yaml under files directory

$ request_body=$(mktemp)
$ NODE_SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
$ jq -n --arg SSH_KEY "$NODE_SSH_KEY" --arg NMSTATE_YAML1 "$(cat server-a.yaml)" --arg NMSTATE_YAML2 "$(cat server-b.yaml)" --arg NMSTATE_YAML3 "$(cat server-c.yaml)" \
'{
  "ssh_public_key": $SSH_KEY,
  "static_network_config": [
    {
      "network_yaml": $NMSTATE_YAML1,
      "mac_interface_map": [{"mac_address": "02:01:00:00:00:60", "logical_nic_name": "enp1s0"}, {"mac_address": "02:01:00:00:00:70", "logical_nic_name": "enp2s0"}]
    },
    {
      "network_yaml": $NMSTATE_YAML2,
      "mac_interface_map": [{"mac_address": "02:01:00:00:00:61", "logical_nic_name": "enp1s0"}, {"mac_address": "02:01:00:00:00:71", "logical_nic_name": "enp2s0"}]
    },
    {
      "network_yaml": $NMSTATE_YAML3,
      "mac_interface_map": [{"mac_address": "02:01:00:00:00:62", "logical_nic_name": "enp1s0"}, {"mac_address": "02:01:00:00:00:72", "logical_nic_name": "enp2s0"}]
    }
  ]
}' > $request_body

~~~

### Patch the infraenv

~~~bash

$ aicli list infraenv
Storing new token in /root/.aicli/token.txt
+---------------------+--------------------------------------+-----------+-------------------+----------+
|       Infraenv      |                  Id                  |  Cluster  | Openshift Version | Iso Type |
+---------------------+--------------------------------------+-----------+-------------------+----------+
| mycluster_infra-env | 5c1bd683-a6c7-4427-b5ce-de28b6644aeb | mycluster |        4.9        | full-iso |
+---------------------+--------------------------------------+-----------+-------------------+----------+

$ export ASSISTED_SERVICE_URL=https://api.openshift.com
$ export INFRA_ID=5c1bd683-a6c7-4427-b5ce-de28b6644aeb
$ curl -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json"  -X PATCH -d @$request_body ${ASSISTED_SERVICE_URL}/api/assisted-install/v2/infra-envs/${INFRA_ID}
{"cluster_id":"9a78f075-bcf1-4cc3-b128-9da2f8ea3348","cpu_architecture":"x86_64","created_at":"2022-03-03T05:31:33.923255Z","download_url":"https://api.openshift.com/api/assisted-images/images/5c1bd683-a6c7-4427-b5ce-de28b6644aeb?arch=x86_64&image_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NDYyOTk5MzMsInN1YiI6IjVjMWJkNjgzLWE2YzctNDQyNy1iNWNlLWRlMjhiNjY0NGFlYiJ9.dwplNv1W3XX12fZ8lNUx-2sqWFfLE3oPsU9m8P3nQFA&type=full-iso&version=4.9","email_domain":"redhat.com","expires_at":"2022-03-03T09:32:13.000Z","href":"/api/assisted-install/v2/infra-envs/5c1bd683-a6c7-4427-b5ce-de28b6644aeb","id":"5c1bd683-a6c7-4427-b5ce-de28b6644aeb","kind":"InfraEnv","name":"mycluster_infra-env","openshift_version":"4.9","org_id":"1979710","proxy":{},"pull_secret_set":true,"static_network_config":"interfaces:\n- name: bond0\n  type: bond\n  state: up\n  ipv4:\n    address:\n    - ip: 192.168.123.16\n      prefix-length: 24\n    dhcp: false\n    enabled: true\n  link-aggregation:\n    mode: active-backup\n    options:\n      miimon: '140'\n    slaves:\n    - enp1s0\n    - enp2s0\nroutes:\n  config:\n  - destination: 0.0.0.0/0\n    next-hop-address: 192.168.123.1\n    next-hop-interface: bond0\ndns-resolver:\n  config:\n    server:\n      - 192.168.123.1HHHHH02:01:00:00:00:60=enp1s0\n02:01:00:00:00:70=enp2s0ZZZZZinterfaces:\n- name: bond0\n  type: bond\n  state: up\n  ipv4:\n    address:\n    - ip: 192.168.123.17\n      prefix-length: 24\n    dhcp: false\n    enabled: true\n  link-aggregation:\n    mode: active-backup\n    options:\n      miimon: '140'\n    slaves:\n    - enp1s0\n    - enp2s0\nroutes:\n  config:\n  - destination: 0.0.0.0/0\n    next-hop-address: 192.168.123.1\n    next-hop-interface: bond0\ndns-resolver:\n  config:\n    server:\n      - 192.168.123.1HHHHH02:01:00:00:00:61=enp1s0\n02:01:00:00:00:71=enp2s0ZZZZZinterfaces:\n- name: bond0\n  type: bond\n  state: up\n  ipv4:\n    address:\n    - ip: 192.168.123.18\n      prefix-length: 24\n    dhcp: false\n    enabled: true\n  link-aggregation:\n    mode: active-backup\n    options:\n      miimon: '140'\n    slaves:\n    - enp1s0\n    - enp2s0\nroutes:\n  config:\n  - destination: 0.0.0.0/0\n    next-hop-address: 192.168.123.1\n    next-hop-interface: bond0\ndns-resolver:\n  config:\n    server:\n      - 192.168.123.1HHHHH02:01:00:00:00:62=enp1s0\n02:01:00:00:00:72=enp2s0","type":"full-iso","updated_at":"2022-03-03T05:32:16.406245Z","user_name":"rhn-support-cchen"}
~~~

## Through aicli

### Update Infraenv

~~~bash

$ aicli update infraenv --paramfile files/static_network_config_bonding.yaml <infraenv ID>

~~~

## Finish the Rest of the Steps

### Download ISO in UI

~~~bash

$ IMAGE=<discovery.iso>

~~~

### Create VMs

~~~bash

$ for i in 0 1 2; do
virt-install -n ocp-master-$i \
--memory 16384 \
--os-variant=fedora-coreos-stable \
--vcpus=4  \
--accelerate  \
--cpu host-passthrough,cache.mode=passthrough  \
--disk path=/home/sno/images/ocp-master-$i.qcow2,size=120  \
--network network=ocp-dev,mac=02:01:00:00:00:6$i  \
--network network=ocp-dev,mac=02:01:00:00:00:7$i \
--cdrom $IMAGE &
done

~~~

### Launch the Deployment in UI
