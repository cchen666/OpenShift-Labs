# Hotfix Procedure

## Where can I download the hotfix release from?

The pullspec for the release payload (4.9.13-assembly.art3657-x86_64) is: quay.io/openshift-release-dev/ocp-release@sha256:2b27d8cc671f79eabdcd010d303e159ae976a22a91e819a66c3931aecf15c119

This OCP hotfix release includes kernel: kernel-4.18.0-305.33.1.el8_4
To compile drivers for this kernel, you can obtain kernel-devel and other kernel related packages from: <https://mirror2.openshift.com/pub/openshift-v4/x86_64/dependencies/hotfixes/art3657/kernel-4.18.0-305.33.1.el8_4__x86_64__fd431d51/>

## Applying Hotfix Payloads

Clear the channel, because we're about to head off-graph to places that do not appear in the Update Service's Cincinnati graph, so the cluster-version operator knows not to attempt to fetch the graph and find the current release:

~~~bash
  $ oc adm upgrade channel --allow-explicit-channel
~~~

The channel subcommand requires a 4.9 or later oc.  For older oc, use:

~~~bash
  $ oc patch clusterversion/version -p '{"spec":{"channel":""}}' --type=merge
~~~

Ask the cluster-version operator to update to the hotfix, using a by-digest @sha256 pullspec:

~~~bash
  $ oc adm upgrade --allow-explicit-upgrade --to-image "${PULLSPEC}"
~~~

## Returning to GA Releases

Because the channel is clear and the hotfix does not appear in Update Service Cincinnati graphs, recommended updates must be monitored manually by cluster administrators or support.  Once a recommended update is identified, request an update using a by-digest @sha256 pullspec:

~~~bash
  $ oc adm upgrade --allow-explicit-upgrade --to-image "${PULLSPEC}"
~~~

After completing the update, restore your prefered channel:

~~~bash
$ oc adm upgrade channel "${CHANNEL}"
~~~

The channel subcommand requires a 4.9 or later oc.  For older oc, use:

~~~bash
  $ oc patch clusterversion/version -p "{\"spec\":{\"channel\":\"${CHANNEL}\"}}" --type=merge
~~~

## Verified Upgrade Paths

•4.9.7-x86_64   ->  4.9.13-assembly.art3657-x86_64
•4.8.25-x86_64  ->  4.9.13-assembly.art3657-x86_64
•4.9.12-x86_64  ->  4.9.13-assembly.art3657-x86_64
•4.7.40-x86_64   ->   4.8.25-x86_64   ->  4.9.13-assembly.art3657-x86_64

## Known Issues

Mt. Bryce Operator Validation:
Intel has encountered a failure with one of its test cases involving the VF clean up use case. Intel is actively investigating the issue.
