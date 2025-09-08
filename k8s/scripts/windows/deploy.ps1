<#
.SYNOPSIS
 Windows deployment script for Core Bank Kubernetes services (infrastructure + apps + monitoring dashboards via inline function).
.DESCRIPTION
 Mirrors linux/deploy.sh logic: deploy namespace, infra (Postgres, Redis, Prometheus, Grafana, Kafka, Discovery), then microservices, ingress/network, optional ServiceMonitors, dashboards import.
#>

param(
    [switch]$SkipDashboards,
    [switch]$SkipCleanup,
    [int]$TimeoutSeconds = 120
)

$ErrorActionPreference = 'Stop'

function Write-Info($m){Write-Host "[INFO] $m" -ForegroundColor Cyan}
function Write-Ok($m){Write-Host "[ OK ] $m" -ForegroundColor Green}
function Write-Warn($m){Write-Host "[WARN] $m" -ForegroundColor Yellow}
function Write-Err($m){Write-Host "[FAIL] $m" -ForegroundColor Red}

function Assert-Kubectl {
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) { Write-Err 'kubectl not found in PATH'; exit 1 }
    if (-not (kubectl cluster-info 2>$null)) { Write-Err 'Cannot connect to Kubernetes cluster'; exit 1 }
}

function Wait-Service {
    param([string]$Name,[string]$Namespace='core-bank',[int]$Timeout=$TimeoutSeconds)
    Write-Info "Waiting for deployment/pods for $Name ..."
    $stopWatch = [Diagnostics.Stopwatch]::StartNew()
    while ($stopWatch.Elapsed.TotalSeconds -lt $Timeout) {
        $pods = kubectl get pods -l app=$Name -n $Namespace --no-headers 2>$null
        if ($LASTEXITCODE -eq 0 -and $pods) {
            $running = ($pods | Select-String 'Running').Count
            $total = ($pods | Measure-Object).Count
            if ($running -gt 0 -and $total -gt 0) { Write-Ok "$Name ready ($running/$total)"; return }
        }
        Start-Sleep -Seconds 5
    }
    Write-Warn "$Name not fully ready within $Timeout s (continuing)"
}

function Apply($path){ kubectl apply -f $path | Out-Null }

Assert-Kubectl

$root = Resolve-Path (Join-Path $PSScriptRoot '..' '..' '..')
Set-Location $root
Write-Info "Working directory: $(Get-Location)"

Write-Info 'Deploying namespace'
Apply 'k8s/deployments/namespace.yml'

Write-Info 'Deploying PostgreSQL'
Apply 'k8s/deployments/postgres.yml'
Wait-Service postgres

Write-Info 'Deploying Redis'
Apply 'k8s/deployments/redis.yml'
Wait-Service redis

Write-Info 'Deploying Prometheus config + deployment'
Apply 'k8s/monitoring/prometheus-config-minimal.yml'
(@'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: core-bank
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:v3.4.0
        ports:
        - containerPort: 9090
        args:
          - '--config.file=/etc/prometheus/prometheus.yml'
          - '--storage.tsdb.path=/prometheus'
          - '--web.console.libraries=/etc/prometheus/console_libraries'
          - '--web.console.templates=/etc/prometheus/consoles'
          - '--storage.tsdb.retention.time=200h'
          - '--web.enable-lifecycle'
        volumeMounts:
        - name: prometheus-config-volume
          mountPath: /etc/prometheus/
          readOnly: true
        resources:
          requests:
            memory: 256Mi
            cpu: 100m
          limits:
            memory: 512Mi
            cpu: 500m
      volumes:
      - name: prometheus-config-volume
        configMap:
          name: prometheus-config
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: core-bank
spec:
  type: ClusterIP
  ports:
  - port: 9090
    targetPort: 9090
    protocol: TCP
  selector:
    app: prometheus
'@) | kubectl apply -f - | Out-Null
Wait-Service prometheus

Write-Info 'Deploying Grafana'
Apply 'k8s/monitoring/grafana.yml'
Wait-Service grafana

Write-Info 'Deploying Discovery Service'
Apply 'k8s/deployments/discovery-service.yml'
Wait-Service discovery-service

Write-Info 'Deploying Kafka'
Apply 'k8s/deployments/kafka.yml'
Wait-Service kafka

Write-Info 'Deploying Account Service'
Apply 'k8s/deployments/account-service.yml'
Wait-Service account-service

Write-Info 'Deploying Customer Service'
Apply 'k8s/deployments/customer-service.yml'
Wait-Service customer-service

Write-Info 'Deploying Transaction Service'
Apply 'k8s/deployments/transaction-service.yml'
Wait-Service transaction-service

Write-Info 'Deploying Authentication Service'
Apply 'k8s/deployments/authentication-service.yml'
Wait-Service authentication-service

Write-Info 'Installing NGINX Ingress (if needed)'
if (-not (kubectl get ingressclass nginx 2>$null)) {
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml | Out-Null
    Write-Info 'Waiting for ingress controller (up to 300s)'
    kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s | Out-Null
} else { Write-Ok 'Ingress already installed' }

Write-Info 'Applying ingress and network policy'
Apply 'k8s/deployments/ingress-loadbalancer.yml'
Apply 'k8s/deployments/network-policy.yml'

Write-Info 'Optional: ServiceMonitors'
if (kubectl get crd servicemonitors.monitoring.coreos.com 2>$null) {
    Apply 'k8s/monitoring/prometheus-servicemonitors.yml'
    Write-Ok 'ServiceMonitors applied'
} else { Write-Warn 'Prometheus Operator CRDs not found, skipping ServiceMonitors' }

if (-not $SkipDashboards) {
    Write-Info 'Setting up Grafana dashboards (port-forward)'
    $pf = Start-Process kubectl -ArgumentList 'port-forward svc/grafana 3000:3000 -n core-bank' -NoNewWindow -PassThru
    try {
        $ready = $false
        for ($i=0; $i -lt 30; $i++) {
            try { $r = Invoke-RestMethod -Uri 'http://localhost:3000/api/health' -TimeoutSec 3 -ErrorAction Stop; $ready = $true; break } catch { Start-Sleep 5 }
        }
        if ($ready) { Write-Ok 'Grafana API ready'; }
        else { Write-Warn 'Grafana not responding; skip dashboards'; break }

        $basicAuth = ('{0}:{1}' -f 'myuser','mypassword')
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($basicAuth)
        $authHeader = 'Basic ' + [Convert]::ToBase64String($bytes)

        Write-Info 'Creating Prometheus datasource'
        $dsBody = '{"name":"Prometheus","type":"prometheus","url":"http://prometheus:9090","access":"proxy","isDefault":true,"jsonData":{"timeInterval":"15s","queryTimeout":"60s","httpMethod":"POST"}}'
        Invoke-RestMethod -Uri 'http://localhost:3000/api/datasources' -Headers @{Authorization=$authHeader} -Method Post -Body $dsBody -ContentType 'application/json' -ErrorAction SilentlyContinue | Out-Null

        $dashFiles = @('monitoring/grafana/dashboards/core-bank-overview.json','monitoring/grafana/dashboards/service-details.json','monitoring/grafana/dashboards/business-metrics.json')
        foreach ($f in $dashFiles) {
            if (Test-Path $f) {
                Write-Info "Importing dashboard $(Split-Path $f -Leaf)"
                $content = Get-Content $f -Raw
                try {
                    $json = $content | ConvertFrom-Json -ErrorAction Stop
                    if ($json.dashboard) { $payload = ($json | Add-Member -NotePropertyName overwrite -NotePropertyValue $true -PassThru | ConvertTo-Json -Depth 50) }
                    else { $payload = (ConvertTo-Json @{dashboard=($content | ConvertFrom-Json); overwrite=$true} -Depth 50) }
                } catch { $payload = (ConvertTo-Json @{dashboard=($content | ConvertFrom-Json -AsHashtable); overwrite=$true} -Depth 50) }
                Invoke-RestMethod -Uri 'http://localhost:3000/api/dashboards/db' -Headers @{Authorization=$authHeader} -Method Post -Body $payload -ContentType 'application/json' -ErrorAction SilentlyContinue | Out-Null
            } else { Write-Warn "Dashboard file missing: $f" }
        }
        Write-Ok 'Dashboards processed'
    } finally {
        if ($pf -and !$pf.HasExited) { Stop-Process $pf.Id -Force }
    }
}

Write-Host ""
Write-Ok 'Deployment complete!'
Write-Host "Access Summary:" -ForegroundColor Cyan
Write-Host "  Grafana: http://localhost:3000 (myuser/mypassword)"
Write-Host "  Prometheus: http://localhost:9090"
Write-Host "  Services via port-forward: account 8081, transaction 8082, customer 8083, auth 8084" -ForegroundColor Gray

Write-Host "Hosts file suggestion (run as Administrator to modify):" -ForegroundColor Cyan
Write-Host "  Add entries for *.core-bank.local pointing to 127.0.0.1" -ForegroundColor Gray
