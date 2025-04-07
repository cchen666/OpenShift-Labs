# Troubleshooting CSI

   CreateVolume +------------+ DeleteVolume
 +------------->|  CREATED   +--------------+
 |              +---+----^---+              |
 |       Controller |    | Controller       v
+++         Publish |    | Unpublish       +++
|X|          Volume |    | Volume          | |
+-+             +---v----+---+             +-+
                | NODE_READY |
                +---+----^---+
               Node |    | Node
              Stage |    | Unstage
             Volume |    | Volume
                +---v----+---+
                |  VOL_READY |
                +---+----^---+
               Node |    | Node
            Publish |    | Unpublish
             Volume |    | Volume
                +---v----+---+
                | PUBLISHED  |
                +------------+

## CreateVolume Failure

provisioner sidecar will watch PVC objects and call CreateVolume() grpc call, where the developer should implement CreateVolume() function by their own. provisioner sidecar image can be got from github.com/kubernetes-csi/external-provisioner

Symptom: PVC will be stuck in Pending

## CreateVolume Succeeded but AttachDetach Failure

Symptom: 1. PVC will be in Bound status
         2.  The Pod will be stuck in ContainerCreating status
         3.  attachdetach-controller complains "Attach timeout for volume"
         4.  kubelet complains "Unable to attach or mount volumes: unmounted volumes=[xxxx], unattached volumes=[xxxx]: timed out waiting for the condition"

## Who creates volumeAttachment CR

When the workload uses the PV, attachdetach-controller will create volumeAttachment CR to show which node needs the PV. CSI attacher keeps monitoring volumeAttachment CR and attach the volume to the node. ControllerPublishVolume() will be called by the attacher container as soon as volumeAttachment CR is created.

## What is node-driver-registrar

node-driver-registrar registers the node plugins to the kubelet, with node level functions such as nodePublishVolume(). So that kubelet knows which grpc method to call when it creates Pod.

