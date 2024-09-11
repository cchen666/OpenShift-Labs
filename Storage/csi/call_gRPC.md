# How to call CSI gRPC endpoints

## Use csc

### Install csc

<https://github.com/rexray/gocsi/tree/master/csc>

```bash

    $ git clone https://github.com/rexray/gocsi.git
    $ cd rexray/gocsi/csc
    $ make build
```

### NodeGetVolumeStats

1. Get the volume ID

    ```bash
    $ oc get pv <volume_name> -o jsonpath='{.spec.csi.volumeHandle}'
    ```

    1. Get the volume path

    ```bash
    $ mount | grep <volume_id>
    ```

2. Call the NodeGetVolumeStats

    ```bash
    $ ./csc node stats 0001-0011-openshift-storage-0000000000000002-fc485061-0542-438e-bf40-978699dcb201:/var/lib/kubelet/pods/b79226b1-1f41-4fde-912a-b63165074907/volumes/kubernetes.io~csi/pvc-e1016e64-ecb6-43fa-84c0-5ef002221acd/mount --endpoint unix:///var/lib/kubelet/plugins/openshift-storage.rbd.csi.ceph.com/csi.sock
    0001-0011-openshift-storage-0000000000000002-fc485061-0542-438e-bf40-978699dcb201 /var/lib/kubelet/pods/b79226b1-1f41-4fde-912a-b63165074907/volumes/kubernetes.io~csi/pvc-e1016e64-ecb6-43fa-84c0-5ef002221acd/mount 52393099264  52521566208 111689728 BYTES
    3275230 3276800 1570 INODES

    The response is available, total, used for each line. So in the above sample, for bytes, available=52393099264 B, total=52521566208 B, used=111689728 B and the same for Inodes.

    ```

## Use grpcurl

### Install grpcurl

### Download csi.proto

```bash
$ curl -O https://raw.githubusercontent.com/container-storage-interface/spec/master/csi.proto
```

### Use grpcurl to call NodeGetVolumeStats

```bash

sh-5.1# ./grpcurl -d '{"volume_id":"pvc-4d7ec1ba-b62c-4dbe-9373-61f28d0d303d", "volume_path":"/var/lib/kubelet/pods/0508e1e4-fe74-4a7f-b585-8b35ab230553/volumes/kubernetes.io~csi/pvc-4d7ec1ba-b62c-4dbe-9373-61f28d0d303d/mount"}' -proto csi.proto -plaintext -unix /var/lib/kubelet/plugins/cinder.csi.openstack.org/csi.sock csi.v1.Node/NodeGetVolumeStats
{
  "usage": [
    {
      "available": "105072459776",
      "total": "105089261568",
      "used": "24576",
      "unit": "BYTES"
    },
    {
      "available": "6553589",
      "total": "6553600",
      "used": "11",
      "unit": "INODES"
    }
  ]
}

```
