#!/bin/bash
set -e

# Define the base IP address (subnet) and starting offset
IP_BASE="192.0.2."
IP_START_OFFSET=192 # Offset for index calculation, index 0 is IP_START_OFFSET + 1
POD_NAME="mysql"
NAMESPACE="test-03684150"
IPPOLLS_NAME="192.0.2.192-27"

# Function to calculate IP address from given index
calculate_ip() {
  local index=$1
  local ip=$((IP_START_OFFSET + index)) # Adding 1 to convert index to octet
  echo "${IP_BASE}${ip}"
}

# Infinite loop to delete and check the pod's IP
for ((i=1; i<=10000; i++)); do
  echo Attempt $i
  # Force delete the pods
  oc delete pod mysql-0 mysql-1 mysql-2 mysql-3 mysql-4 mysql-5 mysql-6 mysql-7 mysql-8 mysql-9 --namespace "${NAMESPACE}" --grace-period=0 --force || true

  # Wait for the new pod to be running
  while true; do
    NEW_POD_STATUS=$(oc get pod "${POD_NAME}-0" -n "${NAMESPACE}" --ignore-not-found -o jsonpath='{.status.phase}' || true)
    if [[ "${NEW_POD_STATUS}" == "Running" ]]; then
      break
    fi
    sleep 1
  done

  echo "Sleeping 65 seconds to ensure enough time to remove old IP"
  sleep 65

  for ((i=0; i<=9; i++)); do

    NEW_POD_IP=$(oc get pod "mysql-$i" -n "${NAMESPACE}" -o yaml | grep '192.0' | xargs)
    echo "Retrieved IP for new pod: mysql-$i ${NEW_POD_IP}"

    ALLOCATION_INDEX=$(oc get ippools "${IPPOLLS_NAME}" -n openshift-multus -o yaml | grep -P "mysql-${i}\b" -B2 | head -n1 | awk '{print $1}' | tr -d '":')

    # Break loop if index is not found
    if [ -z "$ALLOCATION_INDEX" ]; then
        echo "Allocation index for mysql-$i not found in ippools."
        break
    fi

    # Calculate expected IP based on the allocation index
    EXPECTED_IP=$(calculate_ip "$ALLOCATION_INDEX")
    EXPECTED_IP=$(echo $EXPECTED_IP | xargs)

    # Check if the IPs match
    if [ "$NEW_POD_IP" == "$EXPECTED_IP" ]; then
        echo "The IPs match for mysql-$i: Actual IP is ${NEW_POD_IP} and expected IP is ${EXPECTED_IP}."
    else
        echo "IP mismatch for mysql-$i: Actual IP is ${NEW_POD_IP}, but expected IP based on ippools allocation is ${EXPECTED_IP}."
        # Mismatch detected, exit the loop
        break
    fi
    done
  sleep 1
done