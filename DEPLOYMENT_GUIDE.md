# 🚀 Quick Deployment Guide

This guide shows you how to deploy the Core Bank System with monitoring using the provided deployment scripts.

## 📋 Prerequisites

- **Docker** and **Docker Compose** installed
- **kubectl** (for Kubernetes deployment)
- **8GB+ RAM** recommended
- **Ports available**: 3000, 5432, 6379, 8081-8084, 9090, 9092

---

## 🐳 Docker Compose Deployment

### One-Command Deployment (Recommended)
```bash
# Deploy everything including Grafana dashboards
./deploy.sh
```

### Quick Deployment Options
```bash
# Skip cleanup (faster for development)
./deploy.sh --skip-cleanup

# Deploy without Grafana dashboards
./deploy.sh --skip-dashboards

# Get help
./deploy.sh --help
```

### Manual Deployment Steps

If you prefer manual control:

#### 1. Start Infrastructure
```bash
docker-compose up -d postgres redis kafka
sleep 30  # Wait for services to initialize
```

#### 2. Start Monitoring
```bash
docker-compose up -d prometheus grafana
sleep 20  # Wait for services to start
```

#### 3. Start Discovery Service
```bash
docker-compose up -d discovery-service
sleep 30  # Wait for Eureka to start
```

#### 4. Start Core Services
```bash
docker-compose up -d authentication-service account-service customer-service transaction-service
```

#### 5. Setup Grafana Dashboards
```bash
./k8s/scripts/setup-grafana.sh
```

---

## ☸️ Kubernetes Deployment

All Kubernetes deployment scripts are located in `k8s/scripts/`.

### 🔧 Available Scripts

| Script | Description |
|--------|-------------|
| `setup-cluster.sh` | Set up a local Kubernetes cluster |
| `deploy.sh` | Deploy Core Bank services to Kubernetes |
| `deploy-with-grafana.sh` | Full deployment with Grafana dashboards |
| `setup-grafana.sh` | Set up Grafana dashboards only |
| `smart-dashboard-import.sh` | Import dashboards without duplicates |
| `k8s-status.sh` | Show deployment status and access info |
| `load-balancer.sh` | Manage load balancing and scaling |
| `servicemonitor.sh` | Manage Prometheus ServiceMonitors |
| `troubleshoot.sh` | Debug deployment issues |
| `cleanup.sh` | Clean up all resources |
| `validate-yamls.sh` | Validate YAML configuration |
| `validate-offline.sh` | Validate YAMLs without cluster |

### 🚀 Setup Kubernetes Cluster

```bash
# Set up a local cluster (Docker Desktop, minikube, or Kind)
./k8s/scripts/setup-cluster.sh
```

This script helps configure:
- **Docker Desktop**: Enable Kubernetes in settings
- **minikube**: `minikube start --driver=docker --memory=4096 --cpus=2`
- **Kind**: Creates a cluster with proper configuration

### 📦 Deploy to Kubernetes

#### Basic Deployment
```bash
./k8s/scripts/deploy.sh
```

#### Full Deployment with Grafana (Recommended)
```bash
./k8s/scripts/deploy-with-grafana.sh
```

### 📊 Grafana Dashboard Setup

```bash
# Setup Grafana dashboards only
./k8s/scripts/setup-grafana.sh

# With custom credentials
./k8s/scripts/setup-grafana.sh --username admin --password secret

# With custom Grafana URL
./k8s/scripts/setup-grafana.sh --grafana-url http://my-grafana:3000

# Smart import (prevents duplicates)
./k8s/scripts/smart-dashboard-import.sh
```

### 📈 Check Deployment Status

```bash
# Show full status and access information
./k8s/scripts/k8s-status.sh
```

This displays:
- Pod status summary
- Service endpoints
- Port forwarding commands
- Access URLs

### ⚖️ Load Balancing & Scaling

```bash
# Show current status
./k8s/scripts/load-balancer.sh status

# Scale a service
./k8s/scripts/load-balancer.sh scale account-service 3

# Test load balancing
./k8s/scripts/load-balancer.sh test account-service 8081
```

### 📡 ServiceMonitor Management

```bash
# Check Prometheus Operator status
./k8s/scripts/servicemonitor.sh status

# Deploy ServiceMonitors
./k8s/scripts/servicemonitor.sh deploy

# List ServiceMonitors
./k8s/scripts/servicemonitor.sh list

# Validate configuration
./k8s/scripts/servicemonitor.sh validate
```

### 🔍 Troubleshooting

```bash
# Run comprehensive troubleshooting
./k8s/scripts/troubleshoot.sh

# Troubleshoot specific service
./k8s/scripts/troubleshoot.sh account-service

# Apply common fixes
./k8s/scripts/troubleshoot.sh fix
```

### ✅ Validate Configuration

```bash
# Validate YAML files (requires cluster)
./k8s/scripts/validate-yamls.sh

# Validate offline (no cluster required)
./k8s/scripts/validate-offline.sh
```

### 🧹 Cleanup

```bash
# Remove all Core Bank resources from Kubernetes
./k8s/scripts/cleanup.sh
```

This removes:
- Application services (authentication, account, customer, transaction)
- Infrastructure services (kafka, discovery)
- Monitoring services (grafana, prometheus)
- Data services (redis, postgres)
- Namespace and PVCs

---

## 🌐 Access URLs

After deployment, access these services:

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://localhost:3000 | `myuser` / `mypassword` |
| **Prometheus** | http://localhost:9090 | No auth |
| **Discovery Service** | http://localhost:8761 | No auth |
| **Account API** | http://localhost:8081 | JWT required |
| **Customer API** | http://localhost:8083 | JWT required |
| **Transaction API** | http://localhost:8082 | JWT required |
| **Authentication API** | http://localhost:8084 | No auth |

### Kubernetes Port Forwarding

For Kubernetes deployments, use these commands to access services:

```bash
# Grafana
kubectl port-forward svc/grafana 3000:3000 -n core-bank

# Prometheus
kubectl port-forward svc/prometheus 9090:9090 -n core-bank

# Discovery Service
kubectl port-forward svc/discovery-service 8761:8761 -n core-bank

# Account Service
kubectl port-forward svc/account-service 8081:8081 -n core-bank

# Customer Service
kubectl port-forward svc/customer-service 8083:8083 -n core-bank

# Transaction Service
kubectl port-forward svc/transaction-service 8082:8082 -n core-bank

# Authentication Service
kubectl port-forward svc/authentication-service 8084:8084 -n core-bank
```

---

## 📊 Grafana Dashboards

Three dashboards are automatically imported:

### 1. 📈 Core Bank Overview
- System-wide health and performance
- Service availability and response times
- Resource usage (CPU, Memory)
- Error rates across all services

### 2. 🔍 Service Details
- Individual service metrics
- JVM performance (heap, threads)
- Database connection pools
- Detailed performance breakdowns

### 3. 💰 Business Metrics
- Banking operation counts
- Transaction volumes and types
- Customer activity metrics
- Business KPIs and trends

## 🧪 Testing Your Deployment

### Health Checks
```bash
# Check all services
docker-compose ps

# Test individual services
curl http://localhost:8081/actuator/health    # Account Service
curl http://localhost:8083/actuator/health    # Customer Service
curl http://localhost:8082/actuator/health    # Transaction Service
curl http://localhost:8084/actuator/health    # Authentication Service
```

### Generate Test Data
```bash
# Use Postman collection
# Import: postman/CoreBank-Docker-Compose.postman_collection.json

# Or use curl commands
curl -X POST http://localhost:8084/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password"}'
```

## 🔧 Useful Commands

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f grafana
docker-compose logs -f account-service
```

### Restart Services
```bash
# Restart specific service
docker-compose restart grafana

# Restart all
docker-compose restart
```

### Stop Services
```bash
# Stop all
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

## 🚨 Troubleshooting

### Docker Compose Issues

#### 1. Port Already in Use
```bash
# Check what's using the port
lsof -i :3000

# Kill the process or change ports in docker-compose.yml
```

#### 2. Services Not Starting
```bash
# Check logs
docker-compose logs [service-name]

# Check resources
docker system df
docker system prune  # Clean up if needed
```

#### 3. Grafana Dashboard Issues
```bash
# Re-run dashboard setup
./k8s/scripts/setup-grafana.sh

# Check Grafana logs
docker-compose logs grafana

# Manually import dashboards via UI
```

#### 4. No Data in Dashboards
```bash
# Check Prometheus targets
curl http://localhost:9090/targets

# Verify service metrics endpoints
curl http://localhost:8081/actuator/prometheus
```

### Kubernetes Issues

#### 1. Cluster Connection Failed
```bash
# Check cluster status
kubectl cluster-info

# Verify context
kubectl config current-context
kubectl config get-contexts

# Set up cluster if needed
./k8s/scripts/setup-cluster.sh
```

#### 2. Pods Not Running
```bash
# Run troubleshooting script
./k8s/scripts/troubleshoot.sh

# Check specific service
./k8s/scripts/troubleshoot.sh account-service

# View pod logs
kubectl logs -l app=account-service -n core-bank
```

#### 3. Check Deployment Status
```bash
# Get full status report
./k8s/scripts/k8s-status.sh

# Check all pods
kubectl get pods -n core-bank

# Check events
kubectl get events -n core-bank --sort-by=.metadata.creationTimestamp
```

#### 4. Apply Common Fixes
```bash
# Auto-fix common issues
./k8s/scripts/troubleshoot.sh fix

# Restart a deployment
kubectl rollout restart deployment/account-service -n core-bank
```

### Getting Help

**Docker Compose:**
1. Check service logs: `docker-compose logs [service-name]`
2. Verify network connectivity: `docker network ls`
3. Check resource usage: `docker stats`
4. Review configuration: Check `docker-compose.yml`

**Kubernetes:**
1. Check pod status: `kubectl get pods -n core-bank`
2. View pod logs: `kubectl logs -l app=[service-name] -n core-bank`
3. Describe pod: `kubectl describe pod [pod-name] -n core-bank`
4. Run troubleshooter: `./k8s/scripts/troubleshoot.sh`

## 📚 Next Steps

1. **Import Postman Collection**: `postman/CoreBank-Docker-Compose.postman_collection.json`
2. **Explore Grafana Dashboards**: Start with "Core Bank Overview"
3. **Test API Endpoints**: Use the authentication flow to get JWT tokens
4. **Monitor Performance**: Generate load and watch metrics in real-time
5. **Customize Dashboards**: Add your own metrics and panels

## 🎉 Success!

Your Core Bank System is now running with full monitoring capabilities. Start exploring the APIs and dashboards to see your banking system in action!
