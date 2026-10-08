# PowerShell script to install kube-prometheus-stack
$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Installing kube-prometheus-stack via Helm" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$Namespace = "monitoring"
$ReleaseName = "kube-prometheus-stack"
$ValuesFile = Join-Path $PSScriptRoot "..\helm\kube-prometheus-stack-values.yaml"

if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
    Write-Error "❌ Error: 'helm' is not installed or not in PATH."
    exit 1
}

Write-Host "📦 Adding Prometheus Community Helm Repository..." -ForegroundColor Green
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

Write-Host "📁 Creating monitoring namespace if not exists..." -ForegroundColor Green
kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -

Write-Host "🚀 Installing / Upgrading kube-prometheus-stack chart..." -ForegroundColor Green
helm upgrade --install $ReleaseName prometheus-community/kube-prometheus-stack `
    --namespace $Namespace `
    --values $ValuesFile `
    --wait `
    --timeout 10m

Write-Host "✅ kube-prometheus-stack successfully deployed!" -ForegroundColor Green
kubectl get pods -n $Namespace
