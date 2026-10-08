#!/usr/bin/env bash
set -euo pipefail

echo "=========================================================="
echo " Deploying Multi-Service App, ServiceMonitors & Dashboards"
echo "=========================================================="

BASE_DIR="$(dirname "$0")/.."

echo "🚀 Applying Application manifests..."
kubectl apply -f "${BASE_DIR}/manifests/app/"

echo "📊 Applying ServiceMonitor & Prometheus Alert Rules..."
kubectl apply -f "${BASE_DIR}/manifests/monitoring/"

echo "📈 Provisioning Grafana Dashboard ConfigMap..."
kubectl apply -f "${BASE_DIR}/dashboards/dashboard-configmap.yaml"

echo "⏳ Waiting for App Pods to reach Running state..."
kubectl wait --namespace app \
  --for=condition=ready pod \
  --selector=app=backend \
  --timeout=180s || true

kubectl wait --namespace app \
  --for=condition=ready pod \
  --selector=app=frontend \
  --timeout=180s || true

echo "✅ Multi-Service Application & Observability components successfully deployed!"
echo ""
echo "📌 Accessible Services (via Kind NodePort mappings):"
echo "   - Frontend UI:        http://localhost:30080"
echo "   - Backend API:        http://localhost:30081"
echo "   - Backend Metrics:    http://localhost:30081/metrics"
echo "   - Grafana Dashboard:  http://localhost:30000 (User: admin / Pass: admin)"
echo "   - Prometheus UI:      http://localhost:30090"
echo "   - Alertmanager UI:    http://localhost:30093"
