# PowerShell script to deploy sample app and monitoring resources
$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Deploying Multi-Service App, ServiceMonitors & Dashboards" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$BaseDir = Join-Path $PSScriptRoot ".."

Write-Host "🚀 Applying Application manifests..." -ForegroundColor Green
kubectl apply -f (Join-Path $BaseDir "manifests\app")

Write-Host "📊 Applying ServiceMonitor & Prometheus Alert Rules..." -ForegroundColor Green
kubectl apply -f (Join-Path $BaseDir "manifests\monitoring")

Write-Host "📈 Provisioning Grafana Dashboard ConfigMap..." -ForegroundColor Green
kubectl apply -f (Join-Path $BaseDir "dashboards\dashboard-configmap.yaml")

Write-Host "⏳ Waiting for App Pods..." -ForegroundColor Yellow
kubectl wait --namespace app --for=condition=ready pod --selector=app=backend --timeout=180s
kubectl wait --namespace app --for=condition=ready pod --selector=app=frontend --timeout=180s

Write-Host "✅ Multi-Service Application & Observability components successfully deployed!" -ForegroundColor Green
Write-Host ""
Write-Host "📌 Accessible Services (via Kind NodePort mappings):" -ForegroundColor Cyan
Write-Host "   - Frontend UI:        http://localhost:30080"
Write-Host "   - Backend API:        http://localhost:30081"
Write-Host "   - Backend Metrics:    http://localhost:30081/metrics"
Write-Host "   - Grafana Dashboard:  http://localhost:30000 (User: admin / Pass: admin)"
Write-Host "   - Prometheus UI:      http://localhost:30090"
Write-Host "   - Alertmanager UI:    http://localhost:30093"
