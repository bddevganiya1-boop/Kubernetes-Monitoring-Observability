#!/usr/bin/env bash
set -euo pipefail

echo "=========================================================="
echo " Installing kube-prometheus-stack via Helm"
echo "=========================================================="

NAMESPACE="monitoring"
RELEASE_NAME="kube-prometheus-stack"
VALUES_FILE="$(dirname "$0")/../helm/kube-prometheus-stack-values.yaml"

# Check Helm
if ! command -v helm &> /dev/null; then
    echo "❌ Error: 'helm' is not installed."
    exit 1
fi

echo "📦 Adding Prometheus Community Helm Repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "📁 Creating monitoring namespace if not exists..."
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo "🚀 Installing / Upgrading kube-prometheus-stack chart..."
helm upgrade --install "${RELEASE_NAME}" prometheus-community/kube-prometheus-stack \
    --namespace "${NAMESPACE}" \
    --values "${VALUES_FILE}" \
    --wait \
    --timeout 10m

echo "✅ kube-prometheus-stack successfully deployed!"
echo "⏳ Checking Pod status in namespace '${NAMESPACE}'..."
kubectl get pods -n "${NAMESPACE}"
