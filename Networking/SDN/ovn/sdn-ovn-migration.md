# SDN OVN Offline Migration

1. To back up the configuration for the cluster network, enter the following command:

  ```bash
  $ oc get Network.config.openshift.io cluster -o yaml > cluster-openshift-sdn.yaml
  ```

2. Remove the configuration from the Cluster Network Operator (CNO) configuration object by running the following command:

  ```bash
  $ oc patch Network.operator.openshift.io cluster --type='merge' --patch '{"spec":{"migration":null}}'
  ```

3. To prepare all the nodes for the migration, set the migration field on the CNO configuration object by running the following command:

  ```bash
  $ oc patch Network.operator.openshift.io cluster --type='merge' --patch '{ "spec": { "migration": { "networkType": "OVNKubernetes" } } }'
  ```

4. The above command will roll out the MCP, and all the nodes will reboot once. Verify using the below commands.

  ```bash
   $ oc get mcp
   $ oc get co
   $ oc describe node | egrep "hostname|machineconfig"
   $ oc get machineconfig <config_name> -o yaml | grep ExecStart
  ```

5. To start the migration, configure the OVN-Kubernetes network plugin by using one of the following commands:

  $ oc patch Network.config.openshift.io cluster --type='merge' --patch '{ "spec": { "networkType": "OVNKubernetes" } }'

6. Verify that the Multus daemon set rollout is complete before continuing with subsequent steps:

  $ oc -n openshift-multus rollout status daemonset/multus

7. Reboot the nodes one by one or all by using the script.

8. Confirm that the migration succeeded:

  $ oc get network.config/cluster -o jsonpath='{.status.networkType}{"\n"}'
  $ oc get nodes
  $ oc get co

9. To remove the migration configuration from the CNO configuration object, enter the following command:

  $ oc patch Network.operator.openshift.io cluster --type='merge' --patch '{ "spec": { "migration": null } }'

10. To remove custom configuration for the OpenShift SDN network provider, enter the following command:

  $ oc patch Network.operator.openshift.io cluster --type='merge' --patch '{ "spec": { "defaultNetwork": { "openshiftSDNConfig": null } } }'

11. To remove the OpenShift SDN network provider namespace, enter the following command:

  $ oc delete namespace openshift-sdn

12. After a successful migration operation, remove the network.openshift.io/network-type-migration- annotation from the network.config custom resource by entering the following command:

  $ oc annotate network.config cluster network.openshift.io/network-type-migration-
