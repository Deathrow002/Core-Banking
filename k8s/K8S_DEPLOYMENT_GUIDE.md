# 🚀 Kubernetes Deployment & Grafana Dashboard Setup

This guide shows you how to deploy the Core Bank System to Kubernetes with comprehensive Grafana monitoring.

## 📋 Prerequisites

### Required Tools
- **kubectl** - Kubernetes command-line tool
- **Kubernetes cluster** - Docker Desktop, minikube, kind, or cloud provider
- **8GB+ RAM** recommended for the cluster
- **curl** - For API testing

### Kubernetes Cluster Options

#### Option 1: Docker Desktop (Recommended for local development)
```bash
# Enable Kubernetes in Docker Desktop settings
# Settings > Kubernetes > Enable Kubernetes
```

#### Option 2: minikube
```bash
# Start minikube cluster
minikube start --memory=8192 --cpus=4

# Enable ingress addon (optional)
minikube addons enable ingress
```

#### Option 3: kind (Kubernetes in Docker)
```bash
# Create a kind cluster
kind create cluster --name core-bank

# Set kubectl context
kubectl cluster-info --context kind-core-bank
```

#### Option 4: Cloud Providers (GKE, EKS, AKS)
```bash
# Make sure kubectl is configured for your cloud cluster
kubectl config current-context
```

## 🎯 Deployment Options

### Option 1: One-Command Deployment with Grafana (Recommended)
```bash
cd k8s
./deploy-with-grafana.sh
```

This will:
- ✅ Deploy all services to Kubernetes
- ✅ Setup Grafana with datasource configuration
- ✅ Import all dashboards automatically
- ✅ Setup port forwarding for local access
- ✅ Provide service URLs and management commands

### Option 2: Deployment with Custom Options
```bash
# Deploy without automatic dashboard setup
./deploy-with-grafana.sh --skip-dashboards

# Deploy with port forwarding
./deploy-with-grafana.sh --port-forward

# Deploy to custom namespace
./deploy-with-grafana.sh --namespace my-banking-system

# Get help
./deploy-with-grafana.sh --help
```

### Option 3: Manual Step-by-Step Deployment
```bash
cd k8s

# 1. Create namespace and infrastructure
kubectl apply -f namespace.yml
kubectl apply -f postgres.yml
kubectl apply -f redis.yml
kubectl apply -f zookeeper.yml
kubectl apply -f kafka.yml

# 2. Deploy monitoring
kubectl apply -f prometheus.yml
kubectl apply -f grafana.yml

# 3. Deploy core services
kubectl apply -f discovery-service.yml
kubectl apply -f authentication-service.yml
kubectl apply -f account-service.yml
kubectl apply -f customer-service.yml
kubectl apply -f transaction-service.yml

# 4. Setup dashboards
./setup-k8s-grafana-dashboards.sh
```

### Option 4: Use Existing K8s Deploy Script
```bash
# Use the existing script (without Grafana setup)
./deploy.sh

# Then setup Grafana dashboards separately
./setup-k8s-grafana-dashboards.sh
```

## 🌐 Accessing Services

### Method 1: Port Forwarding (Automatic)
The deployment script automatically sets up port forwarding:

```bash
# Grafana
http://localhost:3000

# Prometheus  
http://localhost:9090

# Core services (setup manually if needed)
kubectl port-forward svc/account-service 8081:8081 -n core-bank
kubectl port-forward svc/customer-service 8083:8083 -n core-bank
kubectl port-forward svc/transaction-service 8082:8082 -n core-bank
kubectl port-forward svc/authentication-service 8084:8084 -n core-bank
```

### Method 2: NodePort (if configured)
```bash
# Get service URLs
kubectl get svc -n core-bank

# Access via node IP and NodePort
# Example: http://<node-ip>:<node-port>
```

### Method 3: LoadBalancer (cloud providers)
```bash
# Check external IPs
kubectl get svc -n core-bank -o wide

# Access via external IP
# Example: http://<external-ip>:3000
```

### Method 4: Ingress (if configured)
```bash
# Check ingress
kubectl get ingress -n core-bank

# Access via ingress host
# Example: http://core-bank.local
```

## 📊 Grafana Dashboard Setup

### Automatic Setup (Included in deployment script)
The `deploy-with-grafana.sh` script automatically:
1. ✅ Creates Prometheus datasource
2. ✅ Imports all 3 dashboards
3. ✅ Configures dashboard provisioning via ConfigMaps

### Manual Dashboard Setup
If automatic setup fails, run:
```bash
./setup-k8s-grafana-dashboards.sh
```

### Manual Dashboard Import (via UI)
1. Open Grafana: http://localhost:3000
2. Login: `myuser` / `mypassword`
3. Go to **Configuration** > **Data Sources**
4. Add Prometheus: `http://prometheus:9090`
5. Go to **Dashboards** > **Import**
6. Import these files:
   - `../monitoring/grafana/dashboards/core-bank-overview.json`
   - `../monitoring/grafana/dashboards/service-details.json`
   - `../monitoring/grafana/dashboards/business-metrics.json`

## 📈 Available Dashboards

### 1. 🏦 Core Bank Overview
- **Purpose**: System-wide health and performance monitoring
- **Metrics**: CPU, Memory, Response Times, Error Rates, Service Availability
- **Use Case**: Operations team dashboard for overall system health

### 2. 🔍 Service Details  
- **Purpose**: Individual microservice deep-dive
- **Metrics**: JVM stats, Thread pools, Database connections, GC metrics
- **Use Case**: Development team dashboard for service optimization

### 3. 💰 Business Metrics
- **Purpose**: Banking operations and business KPIs
- **Metrics**: Transaction volumes, Account operations, Customer activity
- **Use Case**: Business team dashboard for operational insights

## 🧪 Testing Your Deployment

### Health Checks
```bash
# Check all pods
kubectl get pods -n core-bank

# Check services
kubectl get svc -n core-bank

# Test individual service health
kubectl port-forward svc/account-service 8081:8081 -n core-bank &
curl http://localhost:8081/actuator/health
```

### API Testing with Postman
```bash
# Import Kubernetes-specific collection
# File: postman/CoreBank-Kubernetes.postman_collection.json

# Or test manually
kubectl port-forward svc/authentication-service 8084:8084 -n core-bank &
curl -X POST http://localhost:8084/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password"}'
```

### Generate Test Data
```bash
# Scale services to generate more metrics
kubectl scale deployment account-service --replicas=3 -n core-bank
kubectl scale deployment transaction-service --replicas=2 -n core-bank

# Run load tests using Postman Runner or k6
```

## 🔧 Management Commands

### Scaling Services
```bash
# Scale individual services
kubectl scale deployment account-service --replicas=3 -n core-bank
kubectl scale deployment customer-service --replicas=2 -n core-bank

# Auto-scaling (if HPA is configured)
kubectl autoscale deployment account-service --cpu-percent=70 --min=1 --max=5 -n core-bank
```

### Viewing Logs
```bash
# View logs for specific service
kubectl logs -f deployment/account-service -n core-bank

# View logs for all replicas
kubectl logs -f -l app=account-service -n core-bank

# View recent logs
kubectl logs --tail=100 deployment/grafana -n core-bank
```

### Updating Services
```bash
# Update image version
kubectl set image deployment/account-service account-service=myregistry/account-service:v2.0 -n core-bank

# Rolling restart
kubectl rollout restart deployment/account-service -n core-bank

# Check rollout status
kubectl rollout status deployment/account-service -n core-bank
```

### Resource Monitoring
```bash
# Check resource usage
kubectl top pods -n core-bank
kubectl top nodes

# Describe problematic pods
kubectl describe pod <pod-name> -n core-bank
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Pods Not Starting
```bash
# Check pod status
kubectl get pods -n core-bank

# Describe problematic pod
kubectl describe pod <pod-name> -n core-bank

# Check logs
kubectl logs <pod-name> -n core-bank

# Common solutions:
# - Resource constraints: Increase cluster resources
# - Image pull errors: Check image availability
# - Config errors: Verify ConfigMaps and Secrets
```

#### 2. Services Not Accessible
```bash
# Check service endpoints
kubectl get endpoints -n core-bank

# Verify service selectors
kubectl get svc grafana -n core-bank -o yaml

# Test internal connectivity
kubectl run test-pod --image=busybox --rm -it -- wget -O- http://prometheus:9090
```

#### 3. Grafana Dashboard Issues
```bash
# Check Grafana logs
kubectl logs deployment/grafana -n core-bank

# Verify ConfigMaps
kubectl get configmap -n core-bank
kubectl describe configmap grafana-datasources -n core-bank

# Re-setup dashboards
./setup-k8s-grafana-dashboards.sh
```

#### 4. Resource Issues
```bash
# Check cluster resources
kubectl describe nodes
kubectl top nodes

# Check resource requests/limits
kubectl describe pod <pod-name> -n core-bank | grep -A 5 "Requests\|Limits"

# Scale down if needed
kubectl scale deployment --replicas=1 --all -n core-bank
```

### Debugging Commands
```bash
# Get all resources in namespace
kubectl get all -n core-bank

# Check events
kubectl get events -n core-bank --sort-by=.metadata.creationTimestamp

# Network connectivity test
kubectl run netshoot --image=nicolaka/netshoot --rm -it -- bash

# Access Grafana container directly
kubectl exec -it deployment/grafana -n core-bank -- bash
```

## 🗑️ Cleanup

### Remove Specific Services
```bash
# Remove specific deployments
kubectl delete deployment grafana -n core-bank
kubectl delete deployment prometheus -n core-bank
```

### Complete Cleanup
```bash
# Remove entire namespace (WARNING: Deletes everything)
kubectl delete namespace core-bank

# Stop port forwarding
pkill -f "kubectl.*port-forward"
```

### Clean Cluster Resources
```bash
# Remove unused resources
kubectl delete pods --field-selector=status.phase=Succeeded -n core-bank
kubectl delete pods --field-selector=status.phase=Failed -n core-bank
```

## 🎉 Success Checklist

After deployment, verify:

- [ ] All pods are running: `kubectl get pods -n core-bank`
- [ ] Services are accessible: `kubectl get svc -n core-bank`  
- [ ] Grafana is accessible: http://localhost:3000
- [ ] Prometheus is working: http://localhost:9090
- [ ] Dashboards are imported and showing data
- [ ] API endpoints respond to health checks
- [ ] Port forwarding is active (if used)

## 📚 Next Steps

1. **Explore Dashboards**: Start with "Core Bank Overview"
2. **Test APIs**: Use Postman collection for comprehensive testing
3. **Monitor Performance**: Generate load and watch real-time metrics
4. **Scale Services**: Test horizontal pod autoscaling
5. **Set up Alerts**: Configure Prometheus alerting rules
6. **Production Setup**: Consider ingress, TLS, and persistent storage

Your Core Bank System is now running on Kubernetes with full observability! 🚀
