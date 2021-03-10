# JSONPATH

## Single Item

~~~bash

$ oc get csr csr-xm6xp -ojsonpath={.status.certificate}

~~~

## Range

~~~bash
$ oc get fileintegritynodestatuses -ojsonpath='{range .items[*]}{.metadata.name}{"\t"}{.results}{"\n"}{end}'

example-fileintegrity-ip-10-0-133-172.us-east-2.compute.internal [{"condition":"Succeeded","lastProbeTime":"2022-10-14T06:02:54Z"}]
example-fileintegrity-ip-10-0-151-182.us-east-2.compute.internal [{"condition":"Succeeded","lastProbeTime":"2022-10-14T05:55:10Z"}]
example-fileintegrity-ip-10-0-172-37.us-east-2.compute.internal [{"condition":"Succeeded","lastProbeTime":"2022-10-14T06:04:58Z"}]
example-fileintegrity-ip-10-0-188-141.us-east-2.compute.internal [{"condition":"Succeeded","lastProbeTime":"2022-10-14T05:57:25Z"}]
example-fileintegrity-ip-10-0-214-110.us-east-2.compute.internal [{"condition":"Succeeded","lastProbeTime":"2022-10-14T05:55:36Z"}]
example-fileintegrity-ip-10-0-223-39.us-east-2.compute.internal [{"condition":"Succeeded","lastProbeTime":"2022-10-14T06:02:24Z"}]

# namespace1:pod1
# image-name:tag,
# image-name:tag,

# namespace2:pod2
# image-name:tag,
$ oc get pods --all-namespaces -o jsonpath='{range .items[*]}{@.metadata.namespace}:{@.metadata.name}{"\n"}{range .spec.containers[*]}{.image}{","}{end}{"\n"}{end}'

~~~
