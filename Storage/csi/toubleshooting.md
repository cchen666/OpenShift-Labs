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

Symptom: PVC will be stuck in Pending

## CreateVolume Succeeded but AttachDetach Failure

Symptom: 1. PVC will be in Bound status
         2.  The Pod will be stuck in ContainerCreating status
         3.  attachdetach-controller complains "Attach timeout for volume"
         4.  kubelet complains "Unable to attach or mount volumes: unmounted volumes=[xxxx], unattached volumes=[xxxx]: timed out waiting for the condition"
