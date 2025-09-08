<#
.SYNOPSIS
Manage scaling / hosts file setup for services (Windows).
#>
param(
  [ValidateSet('scale','status','test-lb','auto-scale','setup-hosts')][string]$Action='status',
  [string]$Service='account-service',
  [int]$Replicas=3,
  [int]$Port=8081,
  [string]$Namespace='core-bank'
)

function Info($m){Write-Host "[INFO] $m" -ForegroundColor Cyan}
function Ok($m){Write-Host "[ OK ] $m" -ForegroundColor Green}
function Warn($m){Write-Host "[WARN] $m" -ForegroundColor Yellow}

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)){ Write-Host 'kubectl missing' -ForegroundColor Red; exit 1 }

switch ($Action) {
  'scale' { Info "Scaling $Service to $Replicas"; kubectl scale deployment $Service --replicas=$Replicas -n $Namespace; break }
  'status'{ Info 'HPA + Deployments'; kubectl get deployments -n $Namespace; kubectl get hpa -n $Namespace; break }
  'test-lb'{ Info "Curl 5 requests to $Service"; 1..5 | ForEach-Object { curl -s http://localhost:$Port/actuator/health | Out-Null; Write-Host "Request $_" }; break }
  'auto-scale'{ Info 'Autoscale core services'; kubectl autoscale deployment account-service --cpu-percent=70 --min=2 --max=10 -n $Namespace; kubectl autoscale deployment transaction-service --cpu-percent=70 --min=2 --max=10 -n $Namespace; Ok 'HPA configured'; break }
  'setup-hosts'{
      $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
      Info "Add entries to hosts file (requires admin)"
      $entries = @(
        '127.0.0.1 account.core-bank.local'
        '127.0.0.1 transaction.core-bank.local'
        '127.0.0.1 customer.core-bank.local'
        '127.0.0.1 auth.core-bank.local'
        '127.0.0.1 discovery.core-bank.local'
        '127.0.0.1 grafana.core-bank.local'
        '127.0.0.1 prometheus.core-bank.local'
      )
      foreach($e in $entries){ if(-not (Select-String -Path $hostsPath -Pattern $e -Quiet)){ Add-Content -Path $hostsPath -Value $e; Write-Host "Added $e" -ForegroundColor Green } else { Write-Host "Exists: $e" -ForegroundColor Gray } }
      Ok 'Hosts file updated'
    }
}
