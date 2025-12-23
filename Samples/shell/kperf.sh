#!/bin/bash
# set -x
# --- Configuration ---
# Define all parameters in one place

NUM_ATTEMPTS=5
KPERF_COUNT=62
KPERF_PARALLEL=6
SLEEP_DURATION=600
KPERF_NAME="kperf"
KPERF_CHART="./fileserver"

# Define the test cases
# Note: The order in TEST_DESCRIPTIONS must match the order in VALUES_FILES
TEST_DESCRIPTIONS=(
    "2 vfs + bond with whereabouts ips"
    "2 vfs + bond no ips"
    "2 vfs with whereabouts ips"
    "Only 2 vfs"
)

VALUES_FILES=(
    "2vf_bond_whereabouts.yaml"
    "2vf_bond_noips.yaml"
    "2vf_whereabouts.yaml"
    "only_2vf.yaml"
)

# --- Test Execution ---

# Loop through each test case defined in the arrays
for idx in "${!TEST_DESCRIPTIONS[@]}"; do
    description="${TEST_DESCRIPTIONS[$idx]}"
    values_file="${VALUES_FILES[$idx]}"

    echo "================= \"$description\" ================="

    # Run the specified number of attempts for this test case
    for i in $(seq 1 $NUM_ATTEMPTS); do
        echo "ATTEMPT $i"

        # 1. Uninstall
        ./kperf uninstall --name $KPERF_NAME --detail --count $KPERF_COUNT --parallel $KPERF_COUNT >/dev/null 2>&1

        # 2. Sleep
        sleep $SLEEP_DURATION

        # 3. Delete events
        oc delete ev --all >/dev/null 2>&1

        # 4. Install
        ./kperf-20m-para install --name $KPERF_NAME --detail --count $KPERF_COUNT --parallel $KPERF_PARALLEL --chart $KPERF_CHART --values "$values_file"

        # 5. --- YOUR NEW COMMAND ---
	events=$(oc get ev)

        alarm_count=$(echo "$events" | grep -ic "alarm")
        rst_count=$(echo "$events" | grep -ic "RST_STREAM")
        timeout_count=$(echo "$events" | grep -ic "DeadlineExceeded")

        # Fixed the variable name in the echo
        echo "ALARM_COUNT: $alarm_count, RST_STREAM: $rst_count, TIMEOUT_COUNT: $timeout_count"

    done
done

echo "================= All tests complete. ================="