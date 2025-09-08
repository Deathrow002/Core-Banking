<#
.SYNOPSIS
Import Grafana dashboards only (assumes datasource already created) on Windows.
#>
$ErrorActionPreference='Stop'
function Info($m){Write-Host "[INFO] $m" -ForegroundColor Cyan}
function Ok($m){Write-Host "[ OK ] $m" -ForegroundColor Green}
function Warn($m){Write-Host "[WARN] $m" -ForegroundColor Yellow}

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) { Write-Host 'kubectl missing' -ForegroundColor Red; exit 1 }

Info 'Port-forwarding Grafana'
$pf= Start-Process kubectl -ArgumentList 'port-forward svc/grafana 3000:3000 -n core-bank' -NoNewWindow -PassThru
try {
  $ready=$false; for($i=0;$i -lt 20;$i++){ try { Invoke-RestMethod -Uri 'http://localhost:3000/api/health' -TimeoutSec 3 -ErrorAction Stop | Out-Null; $ready=$true; break } catch { Start-Sleep 3 } }
  if (-not $ready){ Warn 'Grafana not reachable'; return }
  $auth='Basic '+[Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes('myuser:mypassword'))
  $dashFiles=@('monitoring/grafana/dashboards/core-bank-overview.json','monitoring/grafana/dashboards/service-details.json','monitoring/grafana/dashboards/business-metrics.json')
  foreach($f in $dashFiles){ if(Test-Path $f){ Info "Import $([IO.Path]::GetFileName($f))"; $raw=Get-Content $f -Raw; $parsed=$raw | ConvertFrom-Json; if($parsed.dashboard){ $payload=($parsed | Add-Member overwrite $true -PassThru | ConvertTo-Json -Depth 40) } else { $payload=(ConvertTo-Json @{dashboard=$parsed; overwrite=$true} -Depth 40) }; Invoke-RestMethod -Uri 'http://localhost:3000/api/dashboards/db' -Headers @{Authorization=$auth} -Method Post -Body $payload -ContentType 'application/json' -ErrorAction SilentlyContinue | Out-Null } else { Warn "Missing: $f" } }
  Ok 'Dashboard import complete'
} finally { if($pf -and !$pf.HasExited){ Stop-Process $pf.Id -Force } }
