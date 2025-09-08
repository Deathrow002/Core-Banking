<#
.SYNOPSIS
 Windows Deployment Guide (interactive menu / reference) for Core Bank.
.DESCRIPTION
 Shows Docker & Kubernetes deployment options with ready-to-run PowerShell and bash equivalents.
#>
param()

$Host.UI.RawUI.WindowTitle = 'Core Bank Deployment Guide (Windows)'

function Line { Write-Host ('='*70) -ForegroundColor DarkCyan }
function Header($t){ Line; Write-Host "🏦  $t" -ForegroundColor Cyan; Line; Write-Host '' }
function Section($t){ Write-Host "`n$t" -ForegroundColor Cyan; Write-Host ('-'*$t.Length) -ForegroundColor Cyan }
function Opt($n,$title,$desc){ Write-Host ("[$n] $title") -ForegroundColor Green; if($desc){ Write-Host ("    $desc") -ForegroundColor Yellow }; Write-Host '' }
function Cmd($c){ Write-Host ("    > $c") -ForegroundColor Magenta }

Header 'Core Bank System - Deployment Guide'

Section 'Docker Compose Deployment'
Opt 1 'Complete Docker Deployment (Dev Recommended)' 'All services + monitoring (Linux & Windows examples)'
Cmd './k8s/scripts/linux/deploy.sh'
Cmd 'powershell -ExecutionPolicy Bypass -File k8s/scripts/windows/deploy.ps1'

Opt 2 'Fast Docker Deployment' 'Skip cleanup for faster iteration'
Cmd './k8s/scripts/linux/deploy.sh --skip-cleanup'
Cmd 'powershell -ExecutionPolicy Bypass -File k8s/scripts/windows/deploy.ps1 --skip-cleanup'

Opt 3 'Docker Services Only' 'Skip dashboards'
Cmd './k8s/scripts/linux/deploy.sh --skip-dashboards'
Cmd 'powershell -ExecutionPolicy Bypass -File k8s/scripts/windows/deploy.ps1 --skip-dashboards'

Opt 4 'Docker Dashboard Setup Only' 'Import Grafana dashboards later'
Cmd './k8s/scripts/linux/setup-grafana.sh'
Cmd 'powershell -ExecutionPolicy Bypass -File k8s/scripts/windows/setup-grafana.ps1'

Opt 5 'Manual Docker Compose' 'Raw docker-compose'
Cmd 'docker-compose up -d'

Section 'Kubernetes Deployment'
Opt 6 'Complete K8s Deployment (Prod Recommended)' 'All infra + services + dashboards'
Cmd './k8s/scripts/linux/deploy-with-grafana.sh'
Cmd 'powershell -ExecutionPolicy Bypass -File k8s/scripts/windows/deploy-with-grafana.ps1'

Opt 7 'K8s Custom Options' 'Port-forward / custom namespace / skip dashboards'
Cmd './k8s/scripts/linux/deploy-with-grafana.sh --port-forward'
Cmd './k8s/scripts/linux/deploy-with-grafana.sh --namespace my-bank'
Cmd './k8s/scripts/linux/deploy-with-grafana.sh --skip-dashboards'
Cmd 'powershell -ExecutionPolicy Bypass -File k8s/scripts/windows/deploy-with-grafana.ps1 --port-forward'
Cmd 'powershell -ExecutionPolicy Bypass -File k8s/scripts/windows/deploy-with-grafana.ps1 --namespace my-bank'
Cmd 'powershell -ExecutionPolicy Bypass -File k8s/scripts/windows/deploy-with-grafana.ps1 --skip-dashboards'

Opt 8 'K8s Dashboard Setup Only'
Cmd './k8s/scripts/linux/setup-grafana.sh'
Cmd 'powershell -ExecutionPolicy Bypass -File k8s/scripts/windows/setup-grafana.ps1'

Opt 9 'Standard K8s Deployment' 'Without Grafana automation'
Cmd './k8s/scripts/linux/deploy.sh'
Cmd 'powershell -ExecutionPolicy Bypass -File k8s/scripts/windows/deploy.ps1'

Opt 10 'Manual K8s Deployment' 'Step-by-step apply'
Cmd 'cd k8s/deployments'
Cmd 'kubectl apply -f namespace.yml'
Cmd 'kubectl apply -f postgres.yml'
Cmd 'kubectl apply -f redis.yml'
Cmd 'kubectl apply -f kafka.yml'
Cmd 'kubectl apply -f prometheus.yml'
Cmd 'kubectl apply -f grafana.yml'
Cmd 'kubectl apply -f account-service.yml customer-service.yml authentication-service.yml discovery-service.yml transaction-service.yml'

Section 'Environment Recommendations'
Write-Host 'Local Development:' -ForegroundColor Yellow
Cmd './k8s/scripts/linux/deploy.sh'
Cmd 'powershell -ExecutionPolicy Bypass -File k8s/scripts/windows/deploy.ps1'
Write-Host 'Testing:' -ForegroundColor Yellow
Cmd './k8s/scripts/linux/deploy-with-grafana.sh'
Cmd 'powershell -ExecutionPolicy Bypass -File k8s/scripts/windows/deploy-with-grafana.ps1'
Write-Host 'Production:' -ForegroundColor Yellow
Cmd './k8s/scripts/linux/deploy-with-grafana.sh'
Cmd 'powershell -ExecutionPolicy Bypass -File k8s/scripts/windows/deploy-with-grafana.ps1'

Section 'Service Access URLs'
Write-Host 'Docker:' -ForegroundColor Green
Cmd 'Grafana     http://localhost:3000 (myuser/mypassword)'
Cmd 'Prometheus  http://localhost:9090'
Cmd 'APIs        http://localhost:8081-8084'
Write-Host 'Kubernetes (port-forward):' -ForegroundColor Green
Cmd 'kubectl port-forward svc/grafana 3000:3000 -n core-bank'
Cmd 'kubectl port-forward svc/prometheus 9090:9090 -n core-bank'

Section 'Grafana Dashboards'
Cmd 'Core Bank Overview  - System health'
Cmd 'Service Details     - JVM & per-service metrics'
Cmd 'Business Metrics    - Banking KPIs'

Section 'Testing & Validation'
Cmd '# docker-compose ps'
Cmd '# kubectl get pods -n core-bank'
Cmd '# curl http://localhost:8081/actuator/health'
Cmd 'postman/CoreBank-Docker-Compose.postman_collection.json'
Cmd 'postman/CoreBank-Kubernetes.postman_collection.json'

Section 'Management Commands'
Write-Host 'Docker:' -ForegroundColor Green
Cmd 'docker-compose logs -f account-service'
Cmd 'docker-compose restart account-service'
Cmd 'docker-compose down'
Cmd 'docker-compose up -d --scale account-service=3'
Write-Host 'Kubernetes:' -ForegroundColor Green
Cmd 'kubectl logs -f deployment/account-service -n core-bank'
Cmd 'kubectl scale deployment account-service --replicas=3 -n core-bank'
Cmd 'kubectl rollout restart deployment/account-service -n core-bank'
Cmd 'kubectl delete namespace core-bank'

Section 'Docs'
Cmd 'DEPLOYMENT_GUIDE.md'
Cmd 'k8s/K8S_DEPLOYMENT_GUIDE.md'
Cmd 'k8s/docs/WINDOWS_K8S_DEPLOYMENT_GUIDE.md'
Cmd 'monitoring/QUICK_START.md'
Cmd 'monitoring/SOLUTION.md'

Section 'Quick Start'
Write-Host 'Local (Docker):' -ForegroundColor Yellow
Cmd './k8s/scripts/linux/deploy.sh'
Cmd 'powershell -ExecutionPolicy Bypass -File k8s/scripts/windows/deploy.ps1'
Write-Host 'Production (K8s):' -ForegroundColor Yellow
Cmd './k8s/scripts/linux/deploy-with-grafana.sh'
Cmd 'powershell -ExecutionPolicy Bypass -File k8s/scripts/windows/deploy-with-grafana.ps1'
Write-Host 'Dashboards only:' -ForegroundColor Yellow
Cmd './k8s/scripts/linux/setup-grafana.sh'
Cmd 'powershell -ExecutionPolicy Bypass -File k8s/scripts/windows/setup-grafana.ps1'

Section 'OS Notes'
Cmd 'Linux/macOS scripts: k8s/scripts/linux/*.sh'
Cmd 'Windows scripts:    k8s/scripts/windows/*.ps1'
Cmd 'Session policy: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass'

Write-Host ''
Write-Host '🎉 Ready to deploy Core Bank! Choose a command above.' -ForegroundColor Cyan