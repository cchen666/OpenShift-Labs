# Name.com API Usage

## Setup Token

<https://www.name.com/account/settings/api>

## List Domains

```bash
$ curl -s -u $NAME_USER:$NAME_TOKEN 'https://api.name.com/v4/domains' | jq .
{
  "domains": [
    {
      "domainName": "cchen.work",
      "locked": true,
      "autorenewEnabled": true,
      "expireDate": "2024-03-21T06:55:06Z",
      "createDate": "2022-03-21T06:55:06Z"
    }
  ]
}
```

## List Records

```bash
$ curl -s -u $NAME_USER:$NAME_TOKEN 'https://api.name.com/v4/domains/cchen.work/records' | jq .
{
  "records": [
    {
      "id": 237360741,
      "domainName": "cchen.work",
      "host": "api.ocp414",
      "fqdn": "api.ocp414.cchen.work.",
      "type": "A",
      "answer": "10.0.XX.XX",
      "ttl": 300
    },
    {
      "id": 237360743,
      "domainName": "cchen.work",
      "host": "*.apps.ocp414",
      "fqdn": "*.apps.ocp414.cchen.work.",
      "type": "A",
      "answer": "10.0.XX.XX",
      "ttl": 300
    }
  ]
}
```

## Create the Record

```bash
$ curl -u $NAME_USER:$NAME_TOKEN 'https://api.name.com/v4/domains/cchen.work/records' -X POST -H 'Content-Type: application/json' --data '{"host":"www","type":"A","answer":"10.0.0.1","ttl":300}'
```

## Delete the Record

```bash
$ curl -u $NAME_USER:$NAME_TOKEN 'https://api.name.com/v4/domains/cchen.work/records/12345' -X DELETE
```
