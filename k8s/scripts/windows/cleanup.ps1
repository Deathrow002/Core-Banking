# PowerShell Cleanup Script for Core Bank Kubernetes Services (ASCII safe)
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Say($msg,[string]$color='White'){ Write-Host $msg -ForegroundColor $color }
function Delete-Resource {
    param(
        [Parameter(Mandatory)][string]$ResourceType,
        [Parameter(Mandatory)][string]$ResourceName,
        [string]$Namespace = 'core-bank'
    )
    # Use delete with --ignore-not-found to avoid error noise
    $out = kubectl delete $ResourceType $ResourceName -n $Namespace --ignore-not-found --wait=false 2>$null
    if ($out) {
        Say "Deleting $ResourceType/$ResourceName" Yellow
    } else {
        Say "Skip (not found): $ResourceType/$ResourceName" DarkGray
    }
}

Say 'Cleaning up Core Bank Kubernetes resources' Cyan
Say '--- Application Services ---' Cyan
Delete-Resource deployment authentication-service
Delete-Resource service authentication-service
Delete-Resource deployment transaction-service
Delete-Resource service transaction-service
Delete-Resource deployment customer-service
Delete-Resource service customer-service
Delete-Resource deployment account-service
Delete-Resource service account-service

Say '--- Infrastructure ---' Cyan
Delete-Resource deployment kafka
Delete-Resource service kafka
Delete-Resource pvc kafka-pvc
Delete-Resource deployment discovery-service
Delete-Resource service discovery-service

Say '--- Monitoring ---' Cyan
Delete-Resource deployment grafana
Delete-Resource service grafana
Delete-Resource pvc grafana-pvc
Delete-Resource deployment prometheus
Delete-Resource service prometheus

Say '--- Data Stores ---' Cyan
Delete-Resource deployment redis
Delete-Resource service redis
Delete-Resource pvc redis-pvc
Delete-Resource deployment postgres
Delete-Resource service postgres
Delete-Resource pvc postgres-pvc

Say '--- Namespace ---' Cyan
$null = kubectl get namespace core-bank --ignore-not-found -o name 2>$null
if ($LASTEXITCODE -eq 0) {
    Say 'Deleting namespace core-bank' Yellow
    kubectl delete namespace core-bank | Out-Null
} else {
    Say 'Namespace core-bank not found (already removed)' DarkGray
}

Say ''
Say 'Remaining resources check:' Cyan
$nsCheck = kubectl get namespace core-bank --ignore-not-found -o name 2>$null
if (-not $nsCheck) {
    Say 'Namespace removed - cleanup complete' Green
} else {
    $res = kubectl get all -n core-bank --no-headers 2>$null
    if ($LASTEXITCODE -ne 0) {
        Say 'Namespace in terminating state or inaccessible; will finalize shortly.' DarkGray
    } elseif (-not $res) {
        Say 'No workload resources remain (namespace still present).' Green
    } else {
        Say 'Residual resources:' Yellow
        kubectl get all -n core-bank
    }
}

Say ''
Say 'Optional manual checks:' Cyan
Say '  kubectl get pv   | findstr core-bank' DarkGray
Say '  kubectl get pvc --all-namespaces | findstr core-bank' DarkGray

Say ''
Say 'Cleanup finished.' Green
