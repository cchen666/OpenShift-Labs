oc get pods -o json \
  | jq -r '.items[]
           | select(.metadata.annotations."k8s.v1.cni.cncf.io/network-status" != null)
           | (.metadata.name + " - " +
              (.metadata.annotations."k8s.v1.cni.cncf.io/network-status"
              | fromjson
              | map(select(.name == "test-03684150/whereaboutsnetwork"))
              | .[].ips[]
              ))' | awk '{print $3}'