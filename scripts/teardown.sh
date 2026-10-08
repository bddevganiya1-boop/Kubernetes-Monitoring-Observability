#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="observability-cluster"

echo "=========================================================="
echo " Tearing Down Kind Observability Cluster"
echo "=========================================================="

if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "🗑️  Deleting cluster '${CLUSTER_NAME}'..."
    kind delete cluster --name "${CLUSTER_NAME}"
    echo "✅ Cluster '${CLUSTER_NAME}' deleted successfully."
else
    echo "ℹ️  Cluster '${CLUSTER_NAME}' does not exist."
fi
