* 1. Operator is usually a pod with Go code running in it. It can either manage sub-component pods' lifecycle including installing, upgrading, or do its own work such as monitoring.

* 2. Cluster Version Operator (CVO) generates cluster-wide operator called `cluster operator`. CVO is created or injected by the installer when the control plane was created.

* 3. Speaking of the installer, the installer firstly create a one-node etcd cluster, then after masters are provisioned, the master nodes join the etcd cluster with totally 4 nodes, and kicks the installer out to form a 3 node etcd cluster. Installer then injects (copy) the containers metadata (mainly yaml files) to the masters and masters create necessary resources based on the yaml files during which CVO is created.

* 4. CVO monitors whether there is any update for the cluster operators.

* 5. If you want to rebuild the operator, you need to set `unmanaged` in ClusterVersion.

* 6. An example of rebuilding the operator https://docs.google.com/document/d/1RUUVkj0Pa2xdAazghh0ghMXfLY4L28pKejTMecFdq1k/edit 
