<#
.SYNOPSIS
Display Core Bank Kubernetes deployment options (Windows PowerShell).
#>
param()

function Line(){Write-Host ('='*66) -ForegroundColor DarkCyan}
function Title($t){Line; Write-Host "🏦  $t" -ForegroundColor Cyan; Line}
function Opt($n,$d){Write-Host ("[$n] $d") -ForegroundColor Green}
function Cmd($c){Write-Host ("    > $c") -ForegroundColor Yellow}

Title 'Core Bank - Windows Kubernetes Deployment Options'
Write-Host ''

Opt 1 'Full stack (infra + apps + dashboards)'
Cmd  "powershell -ExecutionPolicy Bypass -File k8s\scripts\windows\deploy-with-grafana.ps1"

Opt 2 'Standard deployment (includes dashboards)'
Cmd  "powershell -ExecutionPolicy Bypass -File k8s\scripts\windows\deploy.ps1"

Opt 3 'Skip dashboards (import later)'
Cmd  "powershell -ExecutionPolicy Bypass -File k8s\scripts\windows\deploy-with-grafana.ps1 -SkipDashboards"
Cmd  "powershell -ExecutionPolicy Bypass -File k8s\scripts\windows\smart-dashboard-import.ps1  # later"

Opt 4 'Validate manifests before deploy'
Cmd  "powershell -ExecutionPolicy Bypass -File k8s\scripts\windows\validate-yamls.ps1"

Opt 5 'Show current status'
Cmd  "powershell -ExecutionPolicy Bypass -File k8s\scripts\windows\k8s-status.ps1"

Opt 6 'Troubleshoot a service'
Cmd  "powershell -ExecutionPolicy Bypass -File k8s\scripts\windows\troubleshoot.ps1 -Service account-service"

Opt 7 'Scale / HPA helpers'
Cmd  "powershell -ExecutionPolicy Bypass -File k8s\scripts\windows\load-balancer.ps1 -Action scale -Service account-service -Replicas 3"
Cmd  "powershell -ExecutionPolicy Bypass -File k8s\scripts\windows\load-balancer.ps1 -Action auto-scale"

Opt 8 'Import dashboards only'
Cmd  "powershell -ExecutionPolicy Bypass -File k8s\scripts\windows\setup-grafana.ps1"

Opt 9 'Add hosts entries (admin)'
Cmd  "powershell -ExecutionPolicy Bypass -File k8s\scripts\windows\load-balancer.ps1 -Action setup-hosts"

Opt 10 'Cleanup everything'
Cmd  "powershell -ExecutionPolicy Bypass -File k8s\scripts\windows\cleanup.ps1"

Write-Host ''
Write-Host 'TIP: For a single session only: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass' -ForegroundColor Magenta
Write-Host 'TIP: Use -SkipDashboards for faster redeploy cycles.' -ForegroundColor Magenta