# PowerShell script for port-forwarding observability services
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Port-Forwarding Kubernetes Observability Services" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Note: With Kind configuration, NodePorts are already directly mapped to localhost." -ForegroundColor Yellow
Write-Host ""
Write-Host "Starting background port-forward jobs..." -ForegroundColor Green

$jobs = @()
$jobs += Start-Job -ScriptBlock { kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80 }
Write-Host "📈 Grafana available at: http://localhost:3000" -ForegroundColor Cyan

$jobs += Start-Job -ScriptBlock { kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090 }
Write-Host "🔥 Prometheus available at: http://localhost:9090" -ForegroundColor Cyan

$jobs += Start-Job -ScriptBlock { kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093 }
Write-Host "🚨 Alertmanager available at: http://localhost:9093" -ForegroundColor Cyan

Write-Host ""
Write-Host "Press Ctrl+C to stop port forwards." -ForegroundColor Yellow

try {
    while ($true) {
        Start-Sleep -Seconds 2
    }
} finally {
    Write-Host "Stopping port-forward jobs..." -ForegroundColor Red
    $jobs | Stop-Job -PassThru | Remove-Job
}
