<#
.SYNOPSIS
Show Kubernetes status and access info (Windows).
#>
param([string]$Namespace='core-bank')
function Section($t){Write-Host "`n=== $t ===" -ForegroundColor Cyan}
function Good($m){Write-Host "[OK] $m" -ForegroundColor Green}
function Warn($m){Write-Host "[WARN] $m" -ForegroundColor Yellow}

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)){ Write-Host 'kubectl missing' -ForegroundColor Red; exit 1 }

Section 'Namespace'
if (kubectl get namespace $Namespace 2>$null){ Good "Namespace $Namespace exists" } else { Warn "Namespace $Namespace missing"; return }

Section 'Pods'
kubectl get pods -n $Namespace

Section 'Services'
kubectl get svc -n $Namespace

Section 'Port Forward Hints'
Write-Host '  kubectl port-forward svc/grafana 3000:3000 -n core-bank'
Write-Host '  kubectl port-forward svc/prometheus 9090:9090 -n core-bank'
Write-Host '  kubectl port-forward svc/account-service 8081:8081 -n core-bank'
Write-Host '  kubectl port-forward svc/transaction-service 8082:8082 -n core-bank'
Write-Host '  kubectl port-forward svc/customer-service 8083:8083 -n core-bank'
Write-Host '  kubectl port-forward svc/authentication-service 8084:8084 -n core-bank'
Write-Host '  kubectl port-forward svc/discovery-service 8761:8761 -n core-bank'
