# PowerShell Cleanup Script for Core Bank Kubernetes Services

Write-Host "🧹 Cleaning up Core Bank services from Kubernetes..."
Write-Host "================================================="

function Delete-Resource {
    param(
        [string]$ResourceType,
        [string]$ResourceName,
        [string]$Namespace = "core-bank"
    )
    $exists = kubectl get $ResourceType $ResourceName -n $Namespace 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "🗑️  Deleting $ResourceType/$ResourceName..."
        kubectl delete $ResourceType $ResourceName -n $Namespace
    } else {
        Write-Host "ℹ️   $ResourceType/$ResourceName not found, skipping..."
    }
}

# Delete application services first
Write-Host "🏦 Deleting application services..."
Delete-Resource deployment authentication-service
Delete-Resource service authentication-service
Delete-Resource deployment transaction-service
Delete-Resource service transaction-service
Delete-Resource deployment customer-service
Delete-Resource service customer-service
Delete-Resource deployment account-service
Delete-Resource service account-service

# Delete infrastructure services
Write-Host "🏗️  Deleting infrastructure services..."
Delete-Resource deployment kafka
Delete-Resource service kafka
Delete-Resource pvc kafka-pvc
Delete-Resource deployment discovery-service
Delete-Resource service discovery-service

# Delete monitoring services
Write-Host "📊 Deleting monitoring services..."
Delete-Resource deployment grafana
Delete-Resource service grafana
Delete-Resource pvc grafana-pvc
Delete-Resource deployment prometheus
Delete-Resource service prometheus

# Delete data services
Write-Host "🗃️  Deleting data services..."
Delete-Resource deployment redis
Delete-Resource service redis
Delete-Resource pvc redis-pvc
Delete-Resource deployment postgres
Delete-Resource service postgres
Delete-Resource pvc postgres-pvc

# Delete namespace (this will clean up any remaining resources)
Write-Host "📦 Deleting namespace..."
$ns = kubectl get namespace core-bank 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "🗑️  Deleting namespace core-bank..."
    kubectl delete namespace core-bank
} else {
    Write-Host "ℹ️   Namespace core-bank not found, skipping..."
}

Write-Host ""
Write-Host "✅ Cleanup completed!"
Write-Host ""
Write-Host "🔍 Remaining resources (should be empty):"
kubectl get all -n core-bank 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "   (namespace not found - cleanup successful)"
}
Write-Host ""
Write-Host "💡 To verify complete cleanup, you can also run:"
Write-Host "   kubectl get pv | findstr core-bank"
Write-Host "   kubectl get pvc --all-namespaces | findstr core-bank"
