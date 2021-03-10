#!/bin/bash
LOGFILE=/tmp/dummy.log

# References
# https://gist.github.com/dougbtv/294b9599d897be55a97396e03cba3dae
# https://github.com/s-matyukevich/bash-cni-plugin/blob/master/01_gcp/bash-cni

# Sample Log
# Tue Nov 1 06:44:20 UTC 2022
# CNI method: DEL
# CNI container id: ae4f2990c1a94ab58e88919d8dae55cd9f3c613f9a98eda566b76afb0d867f8a
# CNI netns: /var/run/netns/2e3c8e50-02be-46ba-860a-ae9cc1fb8dd2
# stdin: {"cniVersion":"0.4.0","name":"my-dummy-network","prevResult":{"cniVersion":"0.4.0","interfaces":[{"name":"dummy"}],"dns":{}},"type":"my-dummy-network"}
#
# Tue Nov 1 06:48:07 UTC 2022
# CNI method: ADD
# CNI container id: d3408bf2fed32c6667977f24e5f93a27491bdc4396cb5b1b1f17a778394b431b
# CNI netns: /var/run/netns/462ae507-891a-4e70-ace9-43da789732fc
# stdin: {"cniVersion":"0.4.0","name":"my-dummy-network","type":"my-dummy-network"}

log () {
  >>$LOGFILE echo $@
}

# Outputs an essentially dummy CNI result that's borderline acceptable by the spec.
# https://github.com/containernetworking/cni/blob/master/SPEC.md#result

cniresult () {
    cat << EOF
{
  "cniVersion": "0.4.0",
  "interfaces": [
      {
          "name": "dummy"
      }
  ],
  "ips": []
}
EOF
}

cniversion() {
cat << EOF
{
  "cniVersion": "0.4.0",
  "supportedVersions": [ "0.3.0", "0.3.1", "0.4.0" ]
}
EOF
}

# Overarching basic parameters.

log `date`

log "CNI method: $CNI_COMMAND"
log "CNI container id: $CNI_CONTAINERID"
log "CNI netns: $CNI_NETNS"

stdin=`cat /dev/stdin`
log "stdin: $stdin"

case $CNI_COMMAND in

ADD)
cniresult
;;

VERSION)
cniversion
;;

*)

;;

esac