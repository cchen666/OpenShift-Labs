# CoreOS

## Set CoreOS kernel Args manually

~~~bash

$ rpm-ostree kargs --editor
$ rpm-ostree kargs --delete <karg1=value1> --append <karg2=value2>
$ reboot

~~~

## Force to re-run the machine-config

~~~bash

$ oc edit node <node>

to change three places:

1. Change currentConfig equal to desiredConfig
    machineconfiguration.openshift.io/currentConfig: rendered-master-8630be694097698cfbf6b7a782ea8e88
    machineconfiguration.openshift.io/desiredConfig: rendered-master-8630be694097698cfbf6b7a782ea8e88

2. Remove the reason
    machineconfiguration.openshift.io/reason: ""

3. Change state to Done

    machineconfiguration.openshift.io/state: Done

Check machine-config-daemon pod logs to locate the underlying problem and use the above steps to 
force the machine-config re-run once
~~~
