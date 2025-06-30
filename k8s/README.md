# Core Bank Kubernetes Deployment with Load Balancing

This directory contains Kubernetes configurations that match the Docker Compose setup for the Core Bank microservices application, enhanced with comprehensive load balancing capabilities.

## Architecture Overview

The deployment includes:

### Infrastructure Services
- **PostgreSQL** (17.5) - Main database
- **Redis** (8.0.2) - Caching and session storage
- **Kafka** (7.5.0) - Message broker with KRaft mode
- **Discovery Service** (8761) - Eureka service registry

### Application Services (Load Balanced)
- **Account Service** (8081) - Account management
  - 3 replicas with HPA (2-10 pods)
  - Round-robin load balancing
  - Circuit breaker protection
- **Customer Service** (8083) - Customer data management
  - 2 replicas with HPA (1-5 pods)
- **Transaction Service** (8082) - Transaction processing
  - 3 replicas with HPA (2-10 pods)
  - Session affinity disabled for stateless processing
- **Authentication Service** (8084) - User authentication
  - 2 replicas with HPA (1-5 pods)

### Monitoring Services
- **Prometheus** (v3.4.0) - Metrics collection
- **Grafana** (12.0.1) - Monitoring dashboards

### Load Balancing Features
- **NGINX Ingress Controller** - External load balancing
- **Kubernetes Services** - Internal load balancing
- **Horizontal Pod Autoscaler (HPA)** - Automatic scaling based on CPU/Memory
- **Pod Disruption Budgets** - High availability during updates
- **Network Policies** - Security and traffic management
- **Service Mesh Ready** - Labels and annotations for Istio/Linkerd

## File Organization

The Kubernetes manifests are organized for clarity and maintainability:

### Core Services
- `namespace.yml` - Core Bank namespace
- `*-service.yml` - Individual service deployments (account, transaction, customer, authentication, discovery)
- `postgres.yml`, `redis.yml`, `kafka.yml` - Infrastructure services
- `prometheus.yml`, `grafana.yml` - Monitoring services

### Load Balancing & Networking
- `ingress-loadbalancer.yml` - NGINX Ingress rules for external load balancing
- `network-policy.yml` - Network security policies
- `core-bank-deployment.yml` - HPA configurations

### Monitoring (Optional)
- `prometheus-servicemonitors.yml` - ServiceMonitor CRDs for Prometheus Operator
  - **Requires**: Prometheus Operator to be installed
  - **Purpose**: Advanced metrics collection from Spring Boot actuator endpoints
  - **Management**: Use `./servicemonitor.sh` script

### Management Scripts
- `deploy.sh` - Complete deployment automation with cluster validation
- `cleanup.sh` - Clean removal of all resources
- `load-balancer.sh` - Load balancing management and testing
- `servicemonitor.sh` - ServiceMonitor management
- `validate-yamls.sh` - YAML validation (requires cluster)
- `validate-offline.sh` - Offline YAML syntax validation
- `setup-cluster.sh` - Interactive cluster setup for local development

## Load Balancing Strategy

### 1. Multi-Layer Load Balancing
```
Internet → NGINX Ingress → K8s Service → Pod Replicas → Eureka Discovery
```

### 2. Scaling Configuration
- **Account Service**: 3 replicas (scales 2-10)
- **Transaction Service**: 3 replicas (scales 2-10)
- **Customer Service**: 2 replicas (scales 1-5)
- **Authentication Service**: 2 replicas (scales 1-5)

### 3. Load Balancing Algorithms
- **External (Ingress)**: Round-robin with health checks
- **Internal (Services)**: Round-robin (sessionAffinity: None)
- **Eureka**: Client-side load balancing
- **HPA**: CPU (70%) and Memory (80%) based scaling

## Deployment

### Prerequisites
- Kubernetes cluster (local or cloud)
- kubectl configured
- NGINX Ingress Controller (auto-installed)
- Metrics server (for HPA - optional)
- Storage class available for PersistentVolumes

### Quick Setup & Deployment

#### 1. Cluster Setup (if needed)
```bash
# Set up a local Kubernetes cluster
./setup-cluster.sh

# Or validate existing cluster connection
kubectl cluster-info
```

#### 2. Validate Manifests (offline)
```bash
# Validate YAML files without requiring a cluster
./validate-offline.sh
```

#### 3. Deploy Services
```bash
# Deploy all services with load balancing
./deploy.sh
```

### Troubleshooting Cluster Connection

If you get an error like:
```
error validating data: failed to download openapi: Get "https://127.0.0.1:6443/openapi/v2?timeout=32s": dial tcp 127.0.0.1:6443: connect: connection refused
```

**Solutions:**

1. **Check cluster status:**
   ```bash
   kubectl cluster-info
   kubectl config current-context
   ```

2. **Set up a local cluster:**
   ```bash
   # Use the interactive setup script
   ./setup-cluster.sh
   
   # Or manually:
   # Docker Desktop: Enable Kubernetes in settings
   # minikube: minikube start
   # Kind: kind create cluster --name core-bank
   ```

3. **Validate without cluster:**
   ```bash
   # Check YAML syntax only
   ./validate-offline.sh
   ```

### Load Balancer Management
```bash
# View current status
./load-balancer.sh status

# Scale services manually
./load-balancer.sh scale account-service 5
./load-balancer.sh scale-all 3

# Test load balancing
./load-balancer.sh test-lb account-service 8081

# Auto-scale for production
./load-balancer.sh auto-scale

# Run stress test
./load-balancer.sh stress-test
```

### Manual Deployment
```bash
# 1. Create namespace
kubectl apply -f namespace.yml

# 2. Deploy infrastructure (in order)
kubectl apply -f postgres.yml
kubectl apply -f redis.yml
kubectl apply -f kafka.yml
kubectl apply -f discovery-service.yml

# 3. Deploy application services with load balancing
kubectl apply -f account-service.yml
kubectl apply -f customer-service.yml
kubectl apply -f transaction-service.yml
kubectl apply -f authentication-service.yml

# 4. Deploy monitoring
kubectl apply -f prometheus.yml
kubectl apply -f grafana.yml

# 5. Deploy load balancer and network policies
kubectl apply -f ingress-loadbalancer.yml
kubectl apply -f network-policy.yml
```

## Access Points

### External Access (Load Balanced via Ingress)
```bash
# Add to /etc/hosts or use DNS
127.0.0.1 account.core-bank.local
127.0.0.1 transaction.core-bank.local
127.0.0.1 customer.core-bank.local
127.0.0.1 auth.core-bank.local
127.0.0.1 discovery.core-bank.local
127.0.0.1 grafana.core-bank.local
127.0.0.1 prometheus.core-bank.local

# Access services
curl http://account.core-bank.local/actuator/health
curl http://transaction.core-bank.local/actuator/health
```

### Direct Access (Port Forward)
```bash
kubectl port-forward svc/account-service 8081:8081 -n core-bank
kubectl port-forward svc/transaction-service 8082:8082 -n core-bank
kubectl port-forward svc/customer-service 8083:8083 -n core-bank
kubectl port-forward svc/authentication-service 8084:8084 -n core-bank
kubectl port-forward svc/discovery-service 8761:8761 -n core-bank
kubectl port-forward svc/grafana 3000:3000 -n core-bank
kubectl port-forward svc/prometheus 9090:9090 -n core-bank
```

## Load Balancing Verification

### 1. Check Pod Distribution
```bash
# View running pods
kubectl get pods -n core-bank -o wide

# Check HPA status
kubectl get hpa -n core-bank

# View service endpoints
kubectl get endpoints -n core-bank
```

### 2. Test Load Balancing
```bash
# Test account service load balancing
./load-balancer.sh test-lb account-service 8081

# Manual testing with curl
for i in {1..10}; do
  kubectl port-forward svc/account-service 8081:8081 -n core-bank &
  sleep 1
  curl -s http://localhost:8081/actuator/info | grep instance || echo "Request $i"
  pkill -f "port-forward"
  sleep 1
done
```

### 3. Monitor Scaling
```bash
# Generate load to trigger HPA
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- \
  sh -c "while true; do wget -q -O- http://account-service:8081/actuator/health; done"

# Watch HPA in action
watch kubectl get hpa -n core-bank
```

## Scaling Commands

### Manual Scaling
```bash
# Scale individual services
kubectl scale deployment account-service --replicas=5 -n core-bank
kubectl scale deployment transaction-service --replicas=4 -n core-bank

# Scale all application services
for service in account-service transaction-service customer-service authentication-service; do
  kubectl scale deployment $service --replicas=3 -n core-bank
done
```

### Auto Scaling Configuration
```yaml
# HPA is configured for each service
# CPU target: 70%
# Memory target: 80%
# Scale up: Fast (0s stabilization)
# Scale down: Slow (300s stabilization)
```

## Monitoring and Observability

### Grafana Dashboards
- **URL**: http://grafana.core-bank.local
- **Credentials**: myuser / mypassword
- **Metrics**: Service health, load balancing, pod scaling

### Prometheus Metrics
- **URL**: http://prometheus.core-bank.local
- **Metrics**: Application metrics, HPA metrics, ingress metrics

### ServiceMonitors (Optional)
ServiceMonitor resources for advanced Prometheus metrics collection are separated into a dedicated file for better organization:

```bash
# Check if Prometheus Operator is installed
./servicemonitor.sh check

# Install Prometheus Operator (if needed)
./servicemonitor.sh install-operator

# Deploy ServiceMonitors
./servicemonitor.sh deploy

# Check ServiceMonitor status
./servicemonitor.sh status

# Validate configuration
./servicemonitor.sh validate
```

**Note**: ServiceMonitors require the Prometheus Operator to be installed. They are optional and the core monitoring works without them.

### Key Metrics to Monitor
- Request distribution across pods
- Response times per pod
- CPU/Memory usage triggering HPA
- Pod startup/shutdown times
- Service discovery registration/deregistration

## Security and Network Policies

### Network Isolation
- Inter-service communication within namespace
- Restricted external access via ingress only
- Database access limited to application pods
- Monitoring access for Prometheus

### Pod Disruption Budgets
- Minimum 1 pod always available during updates
- Graceful rolling updates
- Zero-downtime deployments

## Troubleshooting

### Common Issues

1. **HPA not scaling**
   ```bash
   # Check metrics server
   kubectl top pods -n core-bank
   
   # Check HPA status
   kubectl describe hpa -n core-bank
   ```

2. **Load balancing not working**
   ```bash
   # Check service endpoints
   kubectl get endpoints -n core-bank
   
   # Check ingress status
   kubectl describe ingress -n core-bank
   ```

3. **Pods not starting**
   ```bash
   # Check pod logs
   kubectl logs -f deployment/account-service -n core-bank
   
   # Check events
   kubectl get events -n core-bank --sort-by=.metadata.creationTimestamp
   ```

### Health Checks
```bash
# Check all deployments
kubectl get deployments -n core-bank

# Check all services
kubectl get services -n core-bank

# Check ingress controller
kubectl get pods -n ingress-nginx
```

## Cleanup

```bash
# Remove all resources
./cleanup.sh

# Or manual cleanup
kubectl delete namespace core-bank
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
```

## Best Practices

### Production Considerations
1. **Resource Limits**: All containers have CPU/Memory limits
2. **Health Checks**: Liveness and readiness probes configured
3. **Persistent Storage**: PVCs for data persistence
4. **Network Security**: Network policies restrict traffic
5. **High Availability**: Multiple replicas and HPA
6. **Monitoring**: Comprehensive metrics collection

### Performance Tuning
1. **JVM Tuning**: Configure heap sizes based on limits
2. **Connection Pooling**: Optimize database connections
3. **Cache Configuration**: Tune Redis cache settings
4. **Load Balancer Tuning**: Adjust nginx timeouts and retries

## Files Overview

- `namespace.yml` - Namespace definition
- `postgres.yml` - PostgreSQL with PVC
- `redis.yml` - Redis with PVC and health checks
- `kafka.yml` - Kafka in KRaft mode
- `discovery-service.yml` - Eureka service registry
- `account-service.yml` - Account service with HPA
- `transaction-service.yml` - Transaction service with HPA
- `customer-service.yml` - Customer service with HPA
- `authentication-service.yml` - Authentication service with HPA
- `prometheus.yml` - Prometheus monitoring
- `grafana.yml` - Grafana dashboards
- `ingress-loadbalancer.yml` - NGINX ingress with load balancing
- `network-policy.yml` - Network policies and PDB
- `deploy.sh` - Automated deployment script
- `load-balancer.sh` - Load balancing management script
- `cleanup.sh` - Cleanup script
