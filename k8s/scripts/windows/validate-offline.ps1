<#
.SYNOPSIS
Offline validation: checks for required tools and manifests.
#>
function Info($m){Write-Host "[INFO] $m" -ForegroundColor Cyan}
function Fail($m){Write-Host "[FAIL] $m" -ForegroundColor Red}
function Ok($m){Write-Host "[ OK ] $m" -ForegroundColor Green}

$requirements = @('kubectl','java','docker')
foreach($r in $requirements){ if(Get-Command $r -ErrorAction SilentlyContinue){ Ok "$r found" } else { Fail "$r missing" } }

$paths = @('k8s/deployments/namespace.yml','k8s/deployments/postgres.yml','k8s/deployments/redis.yml','k8s/monitoring/prometheus-config-minimal.yml','monitoring/grafana/dashboards/core-bank-overview.json')
foreach($p in $paths){ if(Test-Path $p){ Ok "$p" } else { Fail "$p missing" } }
