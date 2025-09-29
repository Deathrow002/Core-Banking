<#
.SYNOPSIS
 Comprehensive Windows deployment (infra + apps + monitoring + dashboards) mirroring linux/deploy-with-grafana.sh simplified.
#>
param(
  [switch]$SkipDashboards,
  [switch]$PortForward,
  [string]$Namespace = 'core-bank'
)

$ErrorActionPreference='Stop'

# Pending state tracking
$script:ServiceStatus = @{}
$script:ServiceStartTime = @{}
$script:DeploymentStartTime = Get-Date

# Service categories for tracking
$script:InfrastructureServices = @('postgres', 'redis', 'kafka')
$script:MonitoringServices = @('prometheus', 'grafana')
$script:CoreServices = @('discovery-service', 'authentication-service', 'account-service', 'customer-service', 'transaction-service')
$script:AllServices = $script:InfrastructureServices + $script:MonitoringServices + $script:CoreServices

# Initialize service status
function Initialize-ServiceStatus {
    foreach ($service in $script:AllServices) {
        if ($service) {
            $script:ServiceStatus[$service] = 'pending'
            $script:ServiceStartTime[$service] = $null
        }
    }
    Write-Host "Initialized tracking for $($script:AllServices.Count) services" -ForegroundColor Gray
}

# Update service status
function Set-ServiceStatus {
    param([string]$Service, [string]$Status)
    
    if (-not $Service) {
        Warn "Attempted to set status for null/empty service"
        return
    }
    
    if (-not $script:ServiceStatus.ContainsKey($Service)) {
        $script:ServiceStatus[$Service] = 'pending'
        $script:ServiceStartTime[$Service] = $null
    }
    
    $script:ServiceStatus[$Service] = $Status
    if ($Status -eq 'deploying') {
        $script:ServiceStartTime[$Service] = Get-Date
    }
}

# Get status icon
function Get-StatusIcon {
    param([string]$Status)
    switch ($Status) {
        'pending' { return 'WAIT' }
        'deploying' { return 'WORK' }
        'completed' { return 'DONE' }
        'failed' { return 'FAIL' }
        default { return 'UNKN' }
    }
}

# Get elapsed time for service
function Get-ElapsedTime {
    param([string]$Service)
    
    if (-not $Service -or -not $script:ServiceStartTime.ContainsKey($Service)) {
        return '-'
    }
    
    if ($script:ServiceStartTime[$Service]) {
        $elapsed = (Get-Date) - $script:ServiceStartTime[$Service]
        return "$([int]$elapsed.TotalSeconds)s"
    }
    return '-'
}

# Display deployment status dashboard
function Show-DeploymentStatus {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Blue
    Write-Host "Core Bank System - Kubernetes Deployment" -ForegroundColor Blue
    Write-Host "================================================================" -ForegroundColor Blue
    Write-Host ""
    
    $totalElapsed = (Get-Date) - $script:DeploymentStartTime
    Write-Host "Deployment Status Dashboard" -ForegroundColor Cyan
    Write-Host "===========================" -ForegroundColor Cyan
    Write-Host "Total Elapsed Time: $([int]$totalElapsed.TotalSeconds)s" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Infrastructure Services:" -ForegroundColor Yellow
    foreach ($service in $script:InfrastructureServices) {
        if ($service -and $script:ServiceStatus.ContainsKey($service)) {
            $icon = Get-StatusIcon $script:ServiceStatus[$service]
            $elapsed = Get-ElapsedTime $service
            $status = $script:ServiceStatus[$service]
            $serviceName = $service.ToString().PadRight(20)
            $statusText = $status.ToString().PadRight(12)
            Write-Host "  $serviceName [$icon] $statusText ($elapsed)"
        }
    }
    Write-Host ""
    
    Write-Host "Monitoring Services:" -ForegroundColor Yellow
    foreach ($service in $script:MonitoringServices) {
        if ($service -and $script:ServiceStatus.ContainsKey($service)) {
            $icon = Get-StatusIcon $script:ServiceStatus[$service]
            $elapsed = Get-ElapsedTime $service
            $status = $script:ServiceStatus[$service]
            $serviceName = $service.ToString().PadRight(20)
            $statusText = $status.ToString().PadRight(12)
            Write-Host "  $serviceName [$icon] $statusText ($elapsed)"
        }
    }
    Write-Host ""
    
    Write-Host "Core Banking Services:" -ForegroundColor Yellow
    foreach ($service in $script:CoreServices) {
        if ($service -and $script:ServiceStatus.ContainsKey($service)) {
            $icon = Get-StatusIcon $script:ServiceStatus[$service]
            $elapsed = Get-ElapsedTime $service
            $status = $script:ServiceStatus[$service]
            $serviceName = $service.ToString().PadRight(20)
            $statusText = $status.ToString().PadRight(12)
            Write-Host "  $serviceName [$icon] $statusText ($elapsed)"
        }
    }
    Write-Host ""
    
    # Show progress bar
    $totalServices = $script:AllServices.Count
    $completedServices = ($script:ServiceStatus.Values | Where-Object { $_ -eq 'completed' }).Count
    $progressPercent = if ($totalServices -gt 0) { [int](($completedServices / $totalServices) * 100) } else { 0 }
    $progressBarLength = 30
    $completedLength = [int](($progressPercent / 100) * $progressBarLength)
    
    $progressBar = ("#" * $completedLength) + ("-" * ($progressBarLength - $completedLength))
    Write-Host "Progress: [$progressBar] $progressPercent% ($completedServices/$totalServices services)"
    Write-Host ""
}

function Info($m){Write-Host "[INFO] $m" -ForegroundColor Cyan}
function Ok($m){Write-Host "[OK] $m" -ForegroundColor Green}
function Warn($m){Write-Host "[WARN] $m" -ForegroundColor Yellow}
function Fail($m){Write-Host "[FAIL] $m" -ForegroundColor Red}

function Apply($f){ kubectl apply -f $f | Out-Null }

function WaitSvc([string]$n,[int]$timeout=150){
    if (-not $n) {
        Warn "WaitSvc called with null/empty service name"
        return
    }
    
    Set-ServiceStatus $n 'deploying'
    Show-DeploymentStatus
    
    $spinner = @('|','/','-','\')
    $i = 0
    $sw = [Diagnostics.Stopwatch]::StartNew()
    Info "Waiting for $n to be ready (timeout ${timeout}s)"
    
    while ($sw.Elapsed.TotalSeconds -lt $timeout) {
        $pods = kubectl get pods -l app=$n -n $Namespace --no-headers 2>$null
        if ($LASTEXITCODE -eq 0 -and $pods) {
            $run = ($pods | Select-String 'Running').Count
            $tot = ($pods | Measure-Object).Count
            if ($run -gt 0 -and $tot -gt 0) {
                Write-Host "" # move to new line
                Set-ServiceStatus $n 'completed'
                Show-DeploymentStatus
                Ok "$n ready ($run/$tot) in $([math]::Round($sw.Elapsed.TotalSeconds))s"
                return
            } else {
                $char = $spinner[$i % $spinner.Length]
                Write-Host ("`r[$char] $n deploying ($run/$tot) $([math]::Round($sw.Elapsed.TotalSeconds))s") -NoNewline -ForegroundColor Yellow
                $i++
            }
        } else {
            $char = $spinner[$i % $spinner.Length]
            Write-Host ("`r[$char] $n starting (0/?) $([math]::Round($sw.Elapsed.TotalSeconds))s") -NoNewline -ForegroundColor DarkYellow
            $i++
        }
        
        # Show diagnostic info every 30 seconds for long-running deployments
        if ($sw.Elapsed.TotalSeconds -gt 30 -and ($sw.Elapsed.TotalSeconds % 30) -lt 1) {
            Write-Host ""
            Warn "$n taking longer than expected. Running diagnostics..."
            Diagnose-ServiceIssues $n
            Info "Continuing to wait for $n..."
        }
        
        Start-Sleep 1
    }
    
    Write-Host "" # move to new line
    Set-ServiceStatus $n 'failed'
    Show-DeploymentStatus
    Warn "$n not fully ready in $timeout s"
    
    # Run full diagnostics on failure
    Diagnose-ServiceIssues $n
}

function Fix-ImagePullIssues {
    param([string]$ServiceName)
    
    Write-Host ""
    Write-Host "Fixing image pull issues for: $ServiceName" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Yellow
    
    # Check if this is a custom service that needs local image
    $customServices = @('discovery-service', 'account-service', 'customer-service', 'transaction-service', 'authentication-service')
    
    if ($ServiceName -in $customServices) {
        Info "Attempting to fix image issues for custom service: $ServiceName"
        
        # Try to build the image locally
        $servicePath = Join-Path $root $ServiceName
        if (Test-Path $servicePath) {
            Info "Building Docker image for $ServiceName"
            try {
                docker build -t "$ServiceName:latest" $servicePath
                if ($LASTEXITCODE -eq 0) {
                    Ok "Successfully built image: $ServiceName:latest"
                    
                    # If using kind, load image into kind cluster
                    if (Get-Command kind -ErrorAction SilentlyContinue) {
                        Info "Loading image into kind cluster"
                        kind load docker-image "$ServiceName:latest" 2>$null
                        if ($LASTEXITCODE -eq 0) {
                            Ok "Image loaded into kind cluster"
                        }
                    }
                    
                    # If using minikube, load image into minikube
                    if (Get-Command minikube -ErrorAction SilentlyContinue) {
                        Info "Loading image into minikube"
                        minikube image load "$ServiceName:latest" 2>$null
                        if ($LASTEXITCODE -eq 0) {
                            Ok "Image loaded into minikube"
                        }
                    }
                    
                    # Restart the deployment to pick up the new image
                    Info "Restarting deployment to use new image"
                    kubectl rollout restart deployment/$ServiceName -n $Namespace 2>$null
                    
                } else {
                    Warn "Failed to build image for $ServiceName"
                }
            } catch {
                Warn ("Error building image for $ServiceName" + ": " + $_.Exception.Message)
            }
        } else {
            Warn "Service directory not found: $servicePath"
        }
        
        # Check deployment for image pull policy issues
        Info "Checking deployment configuration"
        $deployment = kubectl get deployment $ServiceName -n $Namespace -o yaml 2>$null
        if ($LASTEXITCODE -eq 0) {
            # Update imagePullPolicy to IfNotPresent for local development
            $patchJson = @"
{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "$ServiceName",
            "imagePullPolicy": "IfNotPresent"
          }
        ]
      }
    }
  }
}
"@
            Info "Updating imagePullPolicy to IfNotPresent"
            echo $patchJson | kubectl patch deployment $ServiceName -n $Namespace --patch-file /dev/stdin 2>$null
            if ($LASTEXITCODE -eq 0) {
                Ok "Updated imagePullPolicy for $ServiceName"
            }
        }
    }
    
    Write-Host ""
}

function Diagnose-ServiceIssues {
    param([string]$ServiceName)
    
    Write-Host ""
    Write-Host "Diagnosing issues for: $ServiceName" -ForegroundColor Yellow
    Write-Host "====================================" -ForegroundColor Yellow
    
    # Check if deployment exists
    $deployment = kubectl get deployment $ServiceName -n $Namespace --no-headers 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[X] Deployment '$ServiceName' not found" -ForegroundColor Red
        
        # Check if the manifest file exists
        $manifestFile = Get-ChildItem $deployDir -Filter "*$ServiceName*" | Select-Object -First 1
        if ($manifestFile) {
            Write-Host "[i] Manifest file found: $($manifestFile.Name)" -ForegroundColor Cyan
            Write-Host "[i] Try applying manually: kubectl apply -f $($manifestFile.FullName)" -ForegroundColor Cyan
        } else {
            Write-Host "[X] No manifest file found for $ServiceName in $deployDir" -ForegroundColor Red
        }
        return
    }
    
    Write-Host "[OK] Deployment exists: $deployment" -ForegroundColor Green
    
    # Check pods
    Write-Host ""
    Write-Host "Pod Status:" -ForegroundColor Cyan
    $pods = kubectl get pods -l app=$ServiceName -n $Namespace 2>$null
    if ($LASTEXITCODE -eq 0 -and $pods) {
        Write-Host $pods
        
        # Check for ErrImagePull or ImagePullBackOff errors
        $podErrors = kubectl get pods -l app=$ServiceName -n $Namespace -o jsonpath='{.items[*].status.containerStatuses[*].state.waiting.reason}' 2>$null
        if ($podErrors -match "ErrImagePull|ImagePullBackOff|ErrImageNeverPull") {
            Warn "Image pull issues detected. Attempting to fix..."
            Fix-ImagePullIssues $ServiceName
        }
        
        # Get pod details
        $podNames = kubectl get pods -l app=$ServiceName -n $Namespace --no-headers -o custom-columns=":metadata.name" 2>$null
        if ($podNames) {
            foreach ($podName in $podNames) {
                if ($podName.Trim()) {
                    Write-Host ""
                    Write-Host "Pod Details for: $podName" -ForegroundColor Cyan
                    kubectl describe pod $podName -n $Namespace | Select-Object -Last 20
                    
                    Write-Host ""
                    Write-Host "Recent Events for: $podName" -ForegroundColor Cyan
                    kubectl get events --field-selector involvedObject.name=$podName -n $Namespace --sort-by='.lastTimestamp' | Select-Object -Last 5
                    
                    # Check logs if pod exists
                    Write-Host ""
                    Write-Host "Recent Logs for: $podName" -ForegroundColor Cyan
                    kubectl logs $podName -n $Namespace --tail=10 2>$null
                    if ($LASTEXITCODE -ne 0) {
                        Write-Host "No logs available (pod may not be running yet)" -ForegroundColor Yellow
                    }
                }
            }
        }
    } else {
        Write-Host "[X] No pods found for $ServiceName" -ForegroundColor Red
    }
    
    # Check service
    Write-Host ""
    Write-Host "Service Status:" -ForegroundColor Cyan
    $service = kubectl get service $ServiceName -n $Namespace 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host $service
    } else {
        Write-Host "[X] Service '$ServiceName' not found" -ForegroundColor Red
    }
    
    # Check recent events in namespace
    Write-Host ""
    Write-Host "Recent Namespace Events:" -ForegroundColor Cyan
    kubectl get events -n $Namespace --sort-by='.lastTimestamp' | Select-Object -Last 10
    
    # Check resource quotas and limits
    Write-Host ""
    Write-Host "Resource Status:" -ForegroundColor Cyan
    kubectl top nodes 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[X] Metrics server not available - cannot check resource usage" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

function Check-Prerequisites {
    Write-Host "Checking Prerequisites..." -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    
    # Check Docker
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        $dockerVersion = docker --version 2>$null
        Write-Host "[OK] Docker: $dockerVersion" -ForegroundColor Green
    } else {
        Write-Host "[X] Docker not found" -ForegroundColor Red
    }
    
    # Check kubectl
    if (Get-Command kubectl -ErrorAction SilentlyContinue) {
        $kubectlVersion = kubectl version --client 2>$null
        if ($LASTEXITCODE -ne 0) {
            # Try alternative version command for older kubectl versions
            $kubectlVersion = kubectl version --client=true 2>$null
        }
        if ($kubectlVersion) {
            Write-Host "[OK] kubectl: $kubectlVersion" -ForegroundColor Green
        } else {
            Write-Host "[OK] kubectl found (version check failed)" -ForegroundColor Green
        }
    } else {
        Write-Host "[X] kubectl not found" -ForegroundColor Red
    }
    
    # Check cluster connection
    $clusterInfo = kubectl cluster-info 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Kubernetes cluster is reachable" -ForegroundColor Green
    } else {
        Write-Host "[X] Cannot connect to Kubernetes cluster" -ForegroundColor Red
    }
    
    # Check namespace
    $namespaceExists = kubectl get namespace $Namespace 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Namespace '$Namespace' exists" -ForegroundColor Green
    } else {
        Write-Host "[X] Namespace '$Namespace' does not exist" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Initialize service status
Initialize-ServiceStatus

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) { Fail 'kubectl missing'; exit 1 }
# Robust cluster reachability check
try {
  kubectl cluster-info | Out-Null
} catch {
  Warn 'kubectl cluster-info failed; attempting node query'
  try {
    $nodes = kubectl get nodes --no-headers 2>$null
    if (-not $nodes) { throw 'No nodes returned' }
    Ok 'Cluster reachable (nodes listed)'
  } catch {
    Fail 'Cluster not reachable. Ensure Docker Desktop Kubernetes is enabled or your cluster is started.'
    Write-Host 'Diagnostics:' -ForegroundColor Yellow
    Write-Host '  kubectl config get-contexts' -ForegroundColor Yellow
    Write-Host '  kubectl config current-context' -ForegroundColor Yellow
    Write-Host '  kubectl get nodes' -ForegroundColor Yellow
    Write-Host 'If using Docker Desktop: Settings > Kubernetes > Enable Kubernetes, then wait until running.' -ForegroundColor Yellow
    Write-Host 'If using minikube: minikube start' -ForegroundColor Yellow
    Write-Host 'If using kind: kind create cluster' -ForegroundColor Yellow
    exit 1
  }
}

# Determine repo root (three levels up from this script directory)
try {
  $root = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName
  if (-not (Test-Path (Join-Path $root 'k8s'))) { throw 'k8s directory not found at computed root' }
  Set-Location $root
  Info "Working directory: $root"
} catch {
  Fail "Unable to resolve repository root: $($_.Exception.Message)"
  exit 1
}

# Define deployDir variable
$deployDir = Join-Path $root 'k8s/deployments'
if (-not (Test-Path $deployDir)) { Fail "Deployments directory not found: $deployDir"; exit 1 }

# Show initial status
Show-DeploymentStatus

# Check prerequisites before starting
Check-Prerequisites

function BuildAndLoadImages {
    $services = @('discovery-service','account-service','customer-service','transaction-service','authentication-service')
    foreach ($svc in $services) {
        $path = Join-Path $root $svc
        if (Test-Path $path) {
            Info "Building Docker image for $svc"
            try {
                docker build -t "$svc:latest" $path | Write-Host
                if ($LASTEXITCODE -eq 0) {
                    Ok "Successfully built $svc:latest"
                    
                    # Load into cluster based on type
                    if (Get-Command kind -ErrorAction SilentlyContinue) {
                        Info "Loading $svc image into kind cluster"
                        try {
                            kind load docker-image "$svc:latest" | Write-Host
                            if ($LASTEXITCODE -eq 0) {
                                Ok "Loaded $svc into kind cluster"
                            }
                        } catch {
                            Warn ("Failed to load $svc into kind: " + $_.Exception.Message)
                        }
                    }
                    
                    # If using Minikube, load the image into Minikube
                    if (Get-Command minikube -ErrorAction SilentlyContinue) {
                        Info "Loading $svc image into Minikube"
                        try {
                            minikube image load "$svc:latest" | Write-Host
                            if ($LASTEXITCODE -eq 0) {
                                Ok "Loaded $svc into minikube"
                            }
                        } catch {
                            Warn ("Failed to load $svc into minikube: " + $_.Exception.Message)
                        }
                    }
                    
                    # For Docker Desktop, the image should be available automatically
                    if (-not (Get-Command kind -ErrorAction SilentlyContinue) -and -not (Get-Command minikube -ErrorAction SilentlyContinue)) {
                        Ok "Image built and available for Docker Desktop Kubernetes"
                    }
                } else {
                    Warn "Failed to build image for $svc"
                }
            } catch {
                Warn ("Failed to build image for $svc" + ": " + $_.Exception.Message)
                continue
            }
        } else {
            Warn "Service folder not found: $path"
        }
    }
    Ok "All available service images built and loaded locally"
}

function Fix-AllImagePullPolicies {
    Info "Fixing imagePullPolicy for all custom services..."
    
    $customServices = @('discovery-service', 'authentication-service', 'account-service', 'customer-service', 'transaction-service')
    
    foreach ($service in $customServices) {
        # Check if deployment exists
        $deployment = kubectl get deployment $service -n $Namespace --no-headers 2>$null
        if ($LASTEXITCODE -eq 0) {
            Info "Updating imagePullPolicy for $service"
            
            # Patch the deployment to use IfNotPresent
            $patchJson = @"
{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "$service",
            "imagePullPolicy": "IfNotPresent"
          }
        ]
      }
    }
  }
}
"@
            
            try {
                $patchJson | kubectl patch deployment $service -n $Namespace --patch-file /dev/stdin 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Ok "Updated imagePullPolicy for $service"
                } else {
                    Warn "Failed to update imagePullPolicy for $service"
                }
            } catch {
                Warn ("Error updating imagePullPolicy for $service" + ": " + $_.Exception.Message)
            }
        }
    }
    
    Ok "Completed imagePullPolicy updates for all services"
}

# Build & load Docker images locally before applying manifests
Info "Building and loading service images locally..."
BuildAndLoadImages

# Apply namespace first (if present)
$nsFile = Join-Path $deployDir 'namespace.yml'
if (Test-Path $nsFile) { Info 'Namespace'; Apply $nsFile } else { Warn 'namespace.yml missing' }

# Gather remaining yaml files excluding namespace (stable ordering)
$deploymentFiles = @(Get-ChildItem $deployDir -Filter *.yml -File; Get-ChildItem $deployDir -Filter *.yaml -File) |
  Where-Object { $_.Name -notin @('namespace.yml','namespace.yaml') } |
  Sort-Object Name -Unique

foreach($file in $deploymentFiles){
  Info "Apply $( $file.Name )"; Apply $file.FullName
}

# Fix image pull policies for all custom services
Fix-AllImagePullPolicies

# Wait for core workloads (if they exist) with enhanced monitoring
$waitApps = @('postgres','redis','kafka','discovery-service','account-service','customer-service','transaction-service','authentication-service')
foreach($app in $waitApps){ 
    Info "Processing $app..."
    
    # Check if the service should exist (has a manifest)
    $manifestFile = Get-ChildItem $deployDir -Filter "*$app*" | Select-Object -First 1
    if (-not $manifestFile -and $app -notin @('prometheus', 'grafana')) {
        Warn "No manifest found for $app, skipping wait"
        Set-ServiceStatus $app 'completed'
        continue
    }
    
    WaitSvc $app 
}

Info "Prometheus minimal config"; Apply 'k8s/monitoring/prometheus-config-minimal.yml'
Info "Prometheus deployment"; Apply 'k8s/monitoring/prometheus-deployment.yml'; WaitSvc prometheus

Info "Grafana"; Apply 'k8s/monitoring/grafana.yml'; WaitSvc grafana

Info 'Ingress Controller check'
if (-not (kubectl get ingressclass nginx 2>$null)) {
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml | Out-Null
  kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s | Out-Null
  Ok 'Ingress installed'
} else { Ok 'Ingress present' }

Info 'Ingress + NetworkPolicy'; Apply 'k8s/deployments/ingress-loadbalancer.yml'; Apply 'k8s/deployments/network-policy.yml'

Info 'ServiceMonitors (optional)'
if (kubectl get crd servicemonitors.monitoring.coreos.com 2>$null) { Apply 'k8s/monitoring/prometheus-servicemonitors.yml'; Ok 'ServiceMonitors applied'} else { Warn 'Operator CRDs missing; skipping' }

if (-not $SkipDashboards) {
  Info 'Dashboard import'
  $pf = Start-Process kubectl -ArgumentList 'port-forward svc/grafana 3000:3000 -n core-bank' -NoNewWindow -PassThru
  try {
    $ready=$false; for($i=0;$i -lt 30;$i++){ try{ Invoke-RestMethod -Uri 'http://localhost:3000/api/health' -TimeoutSec 3 -ErrorAction Stop | Out-Null; $ready=$true; break } catch { Start-Sleep 5 } }
    if ($ready) { Ok 'Grafana API ready' } else { Warn 'Grafana not ready; skip dashboards' }
    if ($ready){
      $authHeader = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes('myuser:mypassword'))
      $dsBody = '{"name":"Prometheus","type":"prometheus","url":"http://prometheus:9090","access":"proxy","isDefault":true,"jsonData":{"timeInterval":"15s","queryTimeout":"60s","httpMethod":"POST"}}'
      Invoke-RestMethod -Uri 'http://localhost:3000/api/datasources' -Headers @{Authorization=$authHeader} -Method Post -Body $dsBody -ContentType 'application/json' -ErrorAction SilentlyContinue | Out-Null
      $dashFiles = @('monitoring/grafana/dashboards/core-bank-overview.json','monitoring/grafana/dashboards/service-details.json','monitoring/grafana/dashboards/business-metrics.json')
      foreach($f in $dashFiles){ if(Test-Path $f){ Info "Import $([IO.Path]::GetFileName($f))"; $raw=Get-Content $f -Raw; try{ $parsed=$raw | ConvertFrom-Json -ErrorAction Stop } catch { Warn "Invalid JSON: $f"; continue }
        if ($parsed.PSObject.Properties.Name -contains 'dashboard'){ $payload=($parsed | Add-Member overwrite $true -PassThru | ConvertTo-Json -Depth 50) } else { $payload=(ConvertTo-Json @{dashboard=$parsed; overwrite=$true} -Depth 50) }
        Invoke-RestMethod -Uri 'http://localhost:3000/api/dashboards/db' -Headers @{Authorization=$authHeader} -Method Post -Body $payload -ContentType 'application/json' -ErrorAction SilentlyContinue | Out-Null }
        else { Warn "Missing dashboard: $f" }
      }
      Ok 'Dashboards processed'
    }
  } finally { if($pf -and !$pf.HasExited){ Stop-Process $pf.Id -Force } }
}

# Final status display
Show-DeploymentStatus

if ($PortForward) { Info 'To access services run kubectl port-forward commands (see status script).' }

# Display final deployment summary
$totalElapsed = (Get-Date) - $script:DeploymentStartTime
$completedServices = ($script:ServiceStatus.Values | Where-Object { $_ -eq 'completed' }).Count
$failedServices = ($script:ServiceStatus.Values | Where-Object { $_ -eq 'failed' }).Count

Write-Host ""
Write-Host "Deployment Summary" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green
Write-Host "Total Time: $([int]$totalElapsed.TotalMinutes)m $([int]$totalElapsed.Seconds)s" -ForegroundColor Yellow
Write-Host "Services Completed: $completedServices/$($script:AllServices.Count)" -ForegroundColor Green
if ($failedServices -gt 0) {
    Write-Host "Services Failed: $failedServices" -ForegroundColor Red
}
Write-Host ""

Ok 'Deployment finished'
Write-Host 'Grafana: http://localhost:3000 (myuser/mypassword)' -ForegroundColor Cyan
Write-Host 'Prometheus: http://localhost:9090' -ForegroundColor Cyan
Write-Host ""
Write-Host "Use 'kubectl get pods -n $Namespace' to check service status" -ForegroundColor Yellow
