<#
.SYNOPSIS
Basic troubleshooting helper (Windows).
#>
param([string]$Namespace='core-bank',[string]$Service='account-service')
function Info($m){Write-Host "[INFO] $m" -ForegroundColor Cyan}
function Line(){Write-Host ('-'*60) -ForegroundColor DarkGray}

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)){ Write-Host 'kubectl missing' -ForegroundColor Red; exit 1 }

Info "Events (recent)"; kubectl get events -n $Namespace --sort-by=.metadata.creationTimestamp | tail -n 20
Line
Info "Pods"; kubectl get pods -n $Namespace -l app=$Service
Line
Info "Describe (first pod)"; $pod=(kubectl get pods -n $Namespace -l app=$Service -o jsonpath='{.items[0].metadata.name}' 2>$null); if($pod){ kubectl describe pod $pod -n $Namespace | head -n 40 }
Line
Info "Logs (first pod)"; if($pod){ kubectl logs $pod -n $Namespace | tail -n 60 }
Line
Info "Service object"; kubectl get svc $Service -n $Namespace -o yaml 2>$null | head -n 30
