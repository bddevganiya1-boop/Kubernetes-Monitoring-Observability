# PowerShell script to teardown Kind cluster
$ErrorActionPreference = "SilentlyContinue"

$ClusterName = "observability-cluster"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Tearing Down Kind Observability Cluster" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$existingClusters = kind get clusters
if ($existingClusters -contains $ClusterName) {
    Write-Host "🗑️  Deleting cluster '$ClusterName'..." -ForegroundColor Yellow
    kind delete cluster --name $ClusterName
    Write-Host "✅ Cluster '$ClusterName' deleted successfully." -ForegroundColor Green
} else {
    Write-Host "ℹ️  Cluster '$ClusterName' does not exist." -ForegroundColor Gray
}
