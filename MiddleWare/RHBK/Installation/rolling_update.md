# Keycloak Update Strategies in Kubernetes: Rolling vs. Recreate

While a Kubernetes `StatefulSet` natively supports zero-downtime rolling updates by sequentially replacing Pods, Keycloak cannot blindly rely on this default behavior. As a heavily stateful application relying on relational databases and in-memory data grids, running mixed versions of Keycloak simultaneously can lead to database schema conflicts and distributed caching failures.

## The Operator's Brain: `update-compatibility`

To prevent split-brain scenarios and data corruption, the Keycloak Operator's `Auto` update strategy does not just look at version numbers. It runs an internal `update-compatibility` check in the background. It compares the existing configuration metadata against the new desired state to determine the safest deployment path.

If the check determines that the new nodes cannot safely co-exist with the old nodes, it overrides Kubernetes' default behavior and forces a **Recreate** update (scaling to 0, then back to N), resulting in a temporary downtime.

## Scenarios: When Does Keycloak Roll vs. Recreate?

| Update Scenario | Operator Action | Underlying Reason |

| :--- | :--- | :--- |

| **Patch Upgrade** (e.g., `26.4.1` -> `26.4.2`) | **Rolling Update** | Database schema and Infinispan clustering protocols remain strictly identical. |

| **UI Theme / Basic Env Vars** | **Rolling Update** | Frontend assets or basic variables have no impact on the distributed state. |

| **Minor/Major Upgrade** (e.g., `26.4` -> `26.5`) | **Recreate** (Downtime) | Built-in Liquibase migrations require exclusive database locks and alter schemas. |

| **Core Feature Toggles** `KC_FEATURES`) | **Recreate** (Downtime) | Mixed nodes might write incompatible session formats into the Infinispan cache, causing deserialization crashes. |

| **Infinispan / JGroups Configs** | **Recreate** (Downtime) | Nodes must share strictly identical networking and serialization rules to form a healthy cluster. |

| **Core SPI / Provider Changes** | **Recreate** (Downtime) | Custom authentication flows or password hashing algorithms missing on older nodes will cause `ProviderNotFoundException`. |

## Best Practices for Incompatible Upgrades (Zero Data Loss)

Whenever a configuration change or version upgrade forces a `Recreate` strategy, you must protect your data from the "data gap" (the time between a live database backup and the actual pod termination).

To achieve a production-grade, zero-data-loss upgrade:

1. **Cut Off Traffic (Maintenance Mode):** Route traffic to a static 503 maintenance page at the Ingress/Load Balancer layer to gracefully sever active connections and stop new database writes.
2. **Scale to Zero:** Modify the Keycloak Custom Resource (CR) to set `instances: 0` to fully stop the application and bring the database to a resting state.
3. **Perform a Hot Backup:** Execute a logical database backup (e.g., `mysqldump --single-transaction`) or take a storage volume snapshot to capture the precise, final data state.
4. **Trigger the Upgrade:** Update the Keycloak CR with the new `image` or configurations, and restore the `instances` count.
5. **Monitor & Restore:** Monitor the `keycloak-0` pod logs for successful database schema migrations. Once all pods are `Ready` and the cluster is reformed, remove the maintenance page and restore traffic.

