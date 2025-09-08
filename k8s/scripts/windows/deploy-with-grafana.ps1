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
function Info($m){Write-Host "[INFO] $m" -ForegroundColor Cyan}
function Ok($m){Write-Host "[ OK ] $m" -ForegroundColor Green}
function Warn($m){Write-Host "[WARN] $m" -ForegroundColor Yellow}
function Fail($m){Write-Host "[FAIL] $m" -ForegroundColor Red}

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) { Fail 'kubectl missing'; exit 1 }
if (-not (kubectl cluster-info *> $null)) { Fail 'Cluster not reachable'; exit 1 }

$root = Resolve-Path (Join-Path $PSScriptRoot '..' '..' '..')
Set-Location $root

function Apply($f){ kubectl apply -f $f | Out-Null }
function WaitSvc([string]$n,[int]$timeout=150){
  $sw=[Diagnostics.Stopwatch]::StartNew();
  while($sw.Elapsed.TotalSeconds -lt $timeout){
    $pods = kubectl get pods -l app=$n -n $Namespace --no-headers 2>$null
    if($LASTEXITCODE -eq 0 -and $pods){
      $run=($pods | Select-String 'Running').Count; $tot=($pods|Measure-Object).Count
      if($run -gt 0 -and $tot -gt 0){Ok "$n ready ($run/$tot)";return}
    }
    Start-Sleep 5
  }
  Warn "$n not fully ready in $timeout s"
}

Info "Namespace"; Apply "k8s/deployments/namespace.yml"
Info "PostgreSQL"; Apply "k8s/deployments/postgres.yml"; WaitSvc postgres
Info "Redis"; Apply "k8s/deployments/redis.yml"; WaitSvc redis
Info "Kafka"; Apply "k8s/deployments/kafka.yml"; WaitSvc kafka

Info "Prometheus minimal config"; Apply 'k8s/monitoring/prometheus-config-minimal.yml'
@'
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
'@ | kubectl apply -f - | Out-Null
WaitSvc prometheus

Info "Grafana"; Apply 'k8s/monitoring/grafana.yml'; WaitSvc grafana
Info "Discovery"; Apply 'k8s/deployments/discovery-service.yml'; WaitSvc discovery-service
Info "Account"; Apply 'k8s/deployments/account-service.yml'; WaitSvc account-service
Info "Customer"; Apply 'k8s/deployments/customer-service.yml'; WaitSvc customer-service
Info "Transaction"; Apply 'k8s/deployments/transaction-service.yml'; WaitSvc transaction-service
Info "Authentication"; Apply 'k8s/deployments/authentication-service.yml'; WaitSvc authentication-service

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

if ($PortForward) { Info 'To access services run kubectl port-forward commands (see status script).' }

Ok 'Deployment finished'
Write-Host 'Grafana: http://localhost:3000 (myuser/mypassword)'
Write-Host 'Prometheus: http://localhost:9090'
