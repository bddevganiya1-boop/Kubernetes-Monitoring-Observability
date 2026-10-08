# PowerShell script to create Multi-Node Kind Cluster
$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Creating Multi-Node Kind Cluster (Observability Stack)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$ClusterName = "observability-cluster"
$ConfigFile = Join-Path $PSScriptRoot "..\kind\kind-cluster-config.yaml"

if (-not (Get-Command kind -ErrorAction SilentlyContinue)) {
    Write-Error "❌ Error: 'kind' is not installed or not in PATH."
    exit 1
}

$existingClusters = kind get clusters
if ($existingClusters -contains $ClusterName) {
    Write-Host "⚠️  Cluster '$ClusterName' already exists." -ForegroundColor Yellow
    kubectl cluster-info --context "kind-$ClusterName"
    exit 0
}

Write-Host "🚀 Creating Kind cluster '$ClusterName' with port mappings..." -ForegroundColor Green
kind create cluster --config $ConfigFile

Write-Host "✅ Kind cluster successfully created!" -ForegroundColor Green
kubectl cluster-info --context "kind-$ClusterName"
kubectl get nodes -o wide
