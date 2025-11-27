# mc client CLI

## Install mc client CLI

```bash

$ wget https://dl.min.io/client/mc/release/linux-amd64/mc
$ chmod +x mc
$ mv mc /usr/local/bin/mc

```

## Create a connection

```bash

$ mc alias set local http://minio-api-http-utilities.apps.ai.cchen.work minio redhat123

```

## Confirm the connection has been created

```bash

$ mc alias list
gcs
  URL       : https://storage.googleapis.com
  AccessKey : YOUR-ACCESS-KEY-HERE
  SecretKey : YOUR-SECRET-KEY-HERE
  API       : S3v2
  Path      : dns
  Src       : /root/.mc/config.json

local
  URL       : http://minio-api-http-utilities.apps.ai.cchen.work
  AccessKey : minio
  SecretKey : redhat123
  API       : s3v4
  Path      : auto
  Src       : /root/.mc/config.json

$ mc admin info local
●  minio-api-http-utilities.apps.ai.cchen.work
   Uptime: 1 day
   Version: 2024-10-02T17:50:41Z
   Network: 1/1 OK
   Drives: 1/1 OK
   Pool: 1

┌──────┬────────────────────────┬─────────────────────┬──────────────┐
│ Pool │ Drives Usage           │ Erasure stripe size │ Erasure sets │
│ 1st  │ 15.7% (total: 558 GiB) │ 1                   │ 1            │
└──────┴────────────────────────┴─────────────────────┴──────────────┘

2.9 GiB Used, 1 Bucket, 13 Objects
1 drive online, 0 drives offline, EC:0

```

## Upload models to minio

```bash

$ mc cp ./Qwen2.5-3B-Instruct local/models --recursive # local is the alias name and models is the bucket name

```
