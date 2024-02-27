IP_BASE="192.0.2"
IP_START_OFFSET=192 # Offset for index calculation, index 0 is IP_START_OFFSET + 1
NAMESPACE="test-03684150"
IPPOOLS_NAME="192.0.2.192-27"

# Fetch the entire allocations node as JSON
allocations_json=$(oc get ippool $IPPOOLS_NAME -o json -n openshift-multus)

# Iterate over each key-value pair in the allocations JSON
echo "${allocations_json}" | jq -r '.spec.allocations | to_entries[] | .key as $index | .value | select(.podref != null) | "\($index) \(.podref)"' | while read -r index podref; do

  # Calculate the expected IP from the allocation index
  # Adjust the calculation if needed to fit your IP address assignment logic
  expected_suffix=$((index + $IP_START_OFFSET))
  expected_ip="$IP_BASE.$expected_suffix"
  pod=`echo $podref | awk -F/ '{print $2}'`
  # Get the actual IP of the pod using the pod reference
  # Assuming that podref includes the namespace, otherwise add '-n <namespace>'
  actual_ip=$(oc get pod "$pod" -o yaml -n $NAMESPACE | grep $IP_BASE | xargs)

  # Compare the actual IP with the expected IP
  if [ "$expected_ip" == "$actual_ip" ]; then
    echo "Pod $pod IP matches: $actual_ip"
  else
    echo "ERROR: Pod $pod IP does NOT match. Expected: $expected_ip, Actual: $actual_ip"
    exit 1
  fi
done