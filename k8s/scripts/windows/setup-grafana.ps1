<#
.SYNOPSIS
Setup Grafana dashboards (datasource + dashboards) for Core Bank on Windows.
#>
param(
  [string]$Namespace='core-bank'
)
$ErrorActionPreference='Stop'
function Info($m){Write-Host "[INFO] $m" -ForegroundColor Cyan}
function Ok($m){Write-Host "[ OK ] $m" -ForegroundColor Green}
function Warn($m){Write-Host "[WARN] $m" -ForegroundColor Yellow}

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) { Write-Host 'kubectl missing' -ForegroundColor Red; exit 1 }

Info 'Port-forwarding Grafana 3000'
$pf = Start-Process kubectl -ArgumentList "port-forward svc/grafana 3000:3000 -n $Namespace" -NoNewWindow -PassThru
try {
  $ready=$false; for($i=0;$i -lt 25;$i++){ try { Invoke-RestMethod -Uri 'http://localhost:3000/api/health' -TimeoutSec 3 -ErrorAction Stop | Out-Null; $ready=$true; break } catch { Start-Sleep 3 } }
  if (-not $ready) { Warn 'Grafana not responding'; return }
  Ok 'Grafana API ready'
  $auth = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes('myuser:mypassword'))
  Info 'Creating Prometheus datasource'
  $ds='{\"name\":\"Prometheus\",\"type\":\"prometheus\",\"url\":\"http://prometheus:9090\",\"access\":\"proxy\",\"isDefault\":true}'
  Invoke-RestMethod -Uri 'http://localhost:3000/api/datasources' -Headers @{Authorization=$auth} -Method Post -Body $ds -ContentType 'application/json' -ErrorAction SilentlyContinue | Out-Null
  $dashFiles = @('monitoring/grafana/dashboards/core-bank-overview.json','monitoring/grafana/dashboards/service-details.json','monitoring/grafana/dashboards/business-metrics.json')
  foreach($f in $dashFiles){ if(Test-Path $f){ Info "Import $([IO.Path]::GetFileName($f))"; $raw=Get-Content $f -Raw; try{ $parsed=$raw | ConvertFrom-Json -ErrorAction Stop } catch { Warn "Invalid JSON: $f"; continue }
      if($parsed.PSObject.Properties.Name -contains 'dashboard'){ $payload=($parsed | Add-Member overwrite $true -PassThru | ConvertTo-Json -Depth 40) } else { $payload=(ConvertTo-Json @{dashboard=$parsed; overwrite=$true} -Depth 40) }
      Invoke-RestMethod -Uri 'http://localhost:3000/api/dashboards/db' -Headers @{Authorization=$auth} -Method Post -Body $payload -ContentType 'application/json' -ErrorAction SilentlyContinue | Out-Null }
    else { Warn "Missing dashboard: $f" }
  }
  Ok 'Dashboards imported'
} finally { if($pf -and !$pf.HasExited){ Stop-Process $pf.Id -Force } }
