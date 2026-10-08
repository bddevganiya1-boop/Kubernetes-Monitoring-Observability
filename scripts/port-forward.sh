#!/usr/bin/env bash
set -euo pipefail

echo "=========================================================="
echo " Port-Forwarding Kubernetes Observability Services"
echo "=========================================================="
echo "Note: If you used Kind with kind-cluster-config.yaml, NodePorts"
echo "are already accessible directly on localhost without port-forwarding."
echo ""
echo "Starting optional port-forwarding background processes..."

# Forward Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80 > /dev/null 2>&1 &
GRAFANA_PID=$!
echo "📈 Grafana available at: http://localhost:3000 (PID: ${GRAFANA_PID})"

# Forward Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090 > /dev/null 2>&1 &
PROM_PID=$!
echo "🔥 Prometheus available at: http://localhost:9090 (PID: ${PROM_PID})"

# Forward Alertmanager
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093 > /dev/null 2>&1 &
ALERT_PID=$!
echo "🚨 Alertmanager available at: http://localhost:9093 (PID: ${ALERT_PID})"

echo ""
echo "Press Ctrl+C to terminate all port forwards."
trap "kill ${GRAFANA_PID} ${PROM_PID} ${ALERT_PID} 2>/dev/null || true; exit 0" INT TERM
wait
