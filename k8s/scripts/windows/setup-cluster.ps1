<#
.SYNOPSIS
Helper to create a local Kubernetes cluster (Docker Desktop or kind/minikube hints).
#>
Write-Host 'Docker Desktop: enable Kubernetes in settings.' -ForegroundColor Cyan
Write-Host 'Minikube:   minikube start --memory=8192 --cpus=4' -ForegroundColor Cyan
Write-Host 'Kind:       kind create cluster --name core-bank' -ForegroundColor Cyan
Write-Host 'Check:      kubectl cluster-info' -ForegroundColor Cyan
