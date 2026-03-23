#!/bin/bash
# snapshot.sh — Capture OVN/OVS state before and after changes
#
# Usage:
#   ./snapshot.sh before          # Save baseline state
#   ./snapshot.sh after           # Save new state and show diff
#   ./snapshot.sh after my-label  # Save with custom label
#
# The diff output shows exactly what changed in NBDB, SBDB, and OVS
# when you create/modify OVN entities.

set -euo pipefail

ACTION="${1:-before}"
LABEL="${2:-default}"
BASE_DIR="/tmp/ovn-snapshots"
DIR="${BASE_DIR}/${ACTION}"

mkdir -p "$DIR"

echo "=== Capturing ${ACTION} state (label: ${LABEL}) ==="

# NBDB
ovn-nbctl show > "${DIR}/nb-show.txt" 2>/dev/null || echo "(no NBDB access)" > "${DIR}/nb-show.txt"

# SBDB
ovn-sbctl show > "${DIR}/sb-show.txt" 2>/dev/null || echo "(no SBDB access)" > "${DIR}/sb-show.txt"
ovn-sbctl lflow-list > "${DIR}/sb-lflows.txt" 2>/dev/null || echo "(no SBDB access)" > "${DIR}/sb-lflows.txt"
ovn-sbctl list Port_Binding > "${DIR}/sb-port-bindings.txt" 2>/dev/null || true
ovn-sbctl list Datapath_Binding > "${DIR}/sb-datapath-bindings.txt" 2>/dev/null || true

# OVS
ovs-vsctl show > "${DIR}/ovs-show.txt" 2>/dev/null || echo "(no OVS access)" > "${DIR}/ovs-show.txt"
ovs-ofctl dump-flows br-int > "${DIR}/ovs-flows.txt" 2>/dev/null || echo "(no br-int)" > "${DIR}/ovs-flows.txt"

# IC (optional — only works on the host running IC databases)
ovn-ic-nbctl ts-list > "${DIR}/ic-nb-ts.txt" 2>/dev/null || true
ovn-ic-sbctl list Availability_Zone > "${DIR}/ic-sb-az.txt" 2>/dev/null || true
ovn-ic-sbctl list Route > "${DIR}/ic-sb-routes.txt" 2>/dev/null || true

echo "State saved to ${DIR}/"

if [ "$ACTION" == "after" ] && [ -d "${BASE_DIR}/before" ]; then
    echo ""
    echo "============================================================"
    echo "  NBDB DIFF (ovn-nbctl show)"
    echo "============================================================"
    diff --color=auto "${BASE_DIR}/before/nb-show.txt" "${DIR}/nb-show.txt" || true

    echo ""
    echo "============================================================"
    echo "  SBDB DIFF (ovn-sbctl show)"
    echo "============================================================"
    diff --color=auto "${BASE_DIR}/before/sb-show.txt" "${DIR}/sb-show.txt" || true

    echo ""
    echo "============================================================"
    echo "  SBDB LOGICAL FLOWS DIFF"
    echo "============================================================"
    # Show count difference instead of full diff (lflows can be huge)
    BEFORE_COUNT=$(wc -l < "${BASE_DIR}/before/sb-lflows.txt")
    AFTER_COUNT=$(wc -l < "${DIR}/sb-lflows.txt")
    echo "Logical flows: ${BEFORE_COUNT} → ${AFTER_COUNT} (delta: $((AFTER_COUNT - BEFORE_COUNT)))"
    echo ""
    echo "New flows (first 30):"
    diff "${BASE_DIR}/before/sb-lflows.txt" "${DIR}/sb-lflows.txt" | grep "^>" | head -30 || echo "(none)"

    echo ""
    echo "============================================================"
    echo "  OVS BRIDGE DIFF (ovs-vsctl show)"
    echo "============================================================"
    diff --color=auto "${BASE_DIR}/before/ovs-show.txt" "${DIR}/ovs-show.txt" || true

    echo ""
    echo "============================================================"
    echo "  OVS OPENFLOW DIFF (first 30 new rules)"
    echo "============================================================"
    BEFORE_FLOW_COUNT=$(wc -l < "${BASE_DIR}/before/ovs-flows.txt")
    AFTER_FLOW_COUNT=$(wc -l < "${DIR}/ovs-flows.txt")
    echo "OpenFlow rules: ${BEFORE_FLOW_COUNT} → ${AFTER_FLOW_COUNT} (delta: $((AFTER_FLOW_COUNT - BEFORE_FLOW_COUNT)))"
    echo ""
    echo "New rules:"
    diff "${BASE_DIR}/before/ovs-flows.txt" "${DIR}/ovs-flows.txt" | grep "^>" | head -30 || echo "(none)"

    echo ""
    echo "============================================================"
    echo "Done. Full snapshots in ${BASE_DIR}/"
    echo "============================================================"
fi
