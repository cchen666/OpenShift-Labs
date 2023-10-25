# ETCD 4.14

## controlPlaneHardwareSpeed

Valid values for `controlPlaneHardwareSpeed`:

* "" (empty string): This is the default options. Maintains traditional OCP etcd-operator behavior.
Allows the system to decide which speed to use.
Enables upgrades from versions where this feature does not exist.
* `Standard`: applies the default etcd timers configuration
Heartbeat Interval=100ms
Election Timeout=1000ms
* `Slower`: applies an etcd timers configuration to operate in unfavorable storage and network conditions
Heartbeat Interval=500ms
Election Timeout=2500ms

```bash
# Change the value. Valid values are "", "Standard", "Slower"
$ oc patch etcd/cluster --type=merge -p '{"spec": {"controlPlaneHardwareSpeed": ""}}'

# *or* set the Standard profile
$ oc patch etcd/cluster --type=merge -p '{"spec": {"controlPlaneHardwareSpeed": "Standard"}}'

# *or* set the Slower profile
$ oc patch etcd/cluster --type=merge -p '{"spec": {"controlPlaneHardwareSpeed": "Slower"}}'

```
