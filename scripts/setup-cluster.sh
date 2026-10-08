#!/usr/bin/env bash
set -euo pipefail

echo "=========================================================="
echo " Creating Multi-Node Kind Cluster (Observability Stack)"
echo "=========================================================="

CLUSTER_NAME="observability-cluster"
CONFIG_FILE="$(dirname "$0")/../kind/kind-cluster-config.yaml"

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "❌ Error: 'kind' is not installed. Please install Kind first."
    exit 1
fi

# Check if docker is running
if ! docker info &> /dev/null; then
    echo "❌ Error: Docker daemon is not running. Please start Docker."
    exit 1
fi

# Check if cluster already exists
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "⚠️  Cluster '${CLUSTER_NAME}' already exists."
    echo "➡️  Use 'kubectl cluster-info --context kind-${CLUSTER_NAME}' to check status."
    exit 0
fi

echo "🚀 Creating Kind cluster '${CLUSTER_NAME}' with custom port mappings..."
kind create cluster --config "${CONFIG_FILE}"

echo "✅ Kind cluster successfully created!"
kubectl cluster-info --context "kind-${CLUSTER_NAME}"
kubectl get nodes -o wide
