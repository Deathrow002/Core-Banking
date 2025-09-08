<#
.SYNOPSIS
Validate Kubernetes YAMLs exist and are parseable (basic) on Windows.
#>
param([string]$Dir='k8s/deployments')
function Info($m){Write-Host "[INFO] $m" -ForegroundColor Cyan}
function Warn($m){Write-Host "[WARN] $m" -ForegroundColor Yellow}

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)){ Write-Host 'kubectl missing' -ForegroundColor Red; exit 1 }

if (-not (Test-Path $Dir)){ Warn "Directory $Dir not found"; exit 1 }

Get-ChildItem $Dir -Filter *.yml | ForEach-Object {
  $f = $_.FullName
  Info "Validating $($_.Name)"
  try { kubectl apply --dry-run=client -f $f 1>$null; Write-Host "  OK" -ForegroundColor Green } catch { Warn "  Invalid: $($_.Exception.Message)" }
}
