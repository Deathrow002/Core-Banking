<#
.SYNOPSIS
Apply Prometheus ServiceMonitors if CRD exists.
#>
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)){ Write-Host 'kubectl missing' -ForegroundColor Red; exit 1 }
if (kubectl get crd servicemonitors.monitoring.coreos.com 2>$null){ kubectl apply -f k8s/monitoring/prometheus-servicemonitors.yml } else { Write-Host 'CRD missing - install operator first' -ForegroundColor Yellow }
