#!/bin/bash

# Kubernetes deployment script that matches docker-compose.yml structure
# This script deploys the Core Bank services in the correct order

set -e

echo "🚀 Deploying Core Bank Services to Kubernetes..."
echo "================================================"

# Check if cluster is accessible
check_cluster_connection() {
    echo "🔍 Checking Kubernetes cluster connection..."
    if kubectl cluster-info &>/dev/null; then
        echo "✅ Connected to Kubernetes cluster"
        return 0
    else
        echo "❌ Cannot connect to Kubernetes cluster"
        echo ""
        echo "Please ensure:"
        echo "  1. A Kubernetes cluster is running (Docker Desktop, minikube, etc.)"
        echo "  2. kubectl is configured to connect to your cluster"
        echo "  3. Current context is set correctly: kubectl config current-context"
        echo ""
        echo "Common solutions:"
        echo "  - Docker Desktop: Enable Kubernetes in Docker Desktop settings"
        echo "  - minikube: Run 'minikube start'"
        echo "  - Kind: Run 'kind create cluster --name core-bank'"
        echo "  - Check context: kubectl config get-contexts"
        echo ""
        exit 1
    fi
}

# Function to wait for deployment to be ready
wait_for_deployment() {
    local deployment_name=$1
    local namespace=${2:-core-bank}
    local timeout=${3:-180}  # Reduced from 600 to 180 seconds (3 minutes)
    
    echo "⏳ Waiting for deployment $deployment_name to be ready..."
    kubectl wait --for=condition=available deployment/$deployment_name -n $namespace --timeout=${timeout}s
    if [ $? -eq 0 ]; then
        echo "✅ $deployment_name is ready"
    else
        echo "❌ $deployment_name failed to become ready within ${timeout} seconds"
        echo "🔍 Checking pod status for debugging..."
        kubectl get pods -l app=$deployment_name -n $namespace
        kubectl describe pods -l app=$deployment_name -n $namespace | tail -20
        echo ""
        echo "💡 Common solutions:"
        echo "  - Check pod logs: kubectl logs -l app=$deployment_name -n $namespace"
        echo "  - Check events: kubectl get events -n $namespace --sort-by=.metadata.creationTimestamp"
        echo "  - Check resources: kubectl top pods -n $namespace"
        exit 1
    fi
}

# Function to wait for pods to be ready
wait_for_pods() {
    local app_label=$1
    local namespace=${2:-core-bank}
    local timeout=${3:-120}  # Reduced from 300 to 120 seconds (2 minutes)
    
    echo "⏳ Waiting for pods with label app=$app_label to be ready..."
    kubectl wait --for=condition=ready pod -l app=$app_label -n $namespace --timeout=${timeout}s
    if [ $? -eq 0 ]; then
        echo "✅ Pods for $app_label are ready"
    else
        echo "❌ Pods for $app_label failed to become ready within ${timeout} seconds"
        exit 1
    fi
}

# Combined function to wait for both deployment and pods (more efficient)
wait_for_service() {
    local service_name=$1
    local namespace=${2:-core-bank}
    local timeout=${3:-180}
    
    echo "⏳ Waiting for $service_name to be fully ready..."
    # Only wait for pods to be ready - this includes deployment availability
    kubectl wait --for=condition=ready pod -l app=$service_name -n $namespace --timeout=${timeout}s
    if [ $? -eq 0 ]; then
        echo "✅ $service_name is ready"
    else
        echo "❌ $service_name failed to become ready within ${timeout} seconds"
        echo "🔍 Debugging information:"
        kubectl get pods -l app=$service_name -n $namespace
        kubectl describe pods -l app=$service_name -n $namespace | tail -20
        echo ""
        echo "💡 Troubleshooting commands:"
        echo "  - kubectl logs -l app=$service_name -n $namespace"
        echo "  - kubectl get events -n $namespace --sort-by=.metadata.creationTimestamp"
        exit 1
    fi
}

# Check cluster connection first
check_cluster_connection

# Set namespace variable
NAMESPACE="core-bank"

# 1. Create namespace
echo "📦 Creating namespace..."
kubectl apply -f k8s/namespace.yml

# 2. Deploy infrastructure services (matching docker-compose dependencies)
echo ""
echo "🏗️  Deploying infrastructure services..."

echo "🐘 Deploying PostgreSQL..."
kubectl apply -f k8s/postgres.yml
wait_for_service "postgres"

echo "🗃️  Deploying Redis..."
kubectl apply -f k8s/redis.yml
wait_for_service "redis"

echo "📊 Deploying Prometheus..."
kubectl apply -f k8s/prometheus.yml
wait_for_service "prometheus"

echo "📈 Deploying Grafana..."
kubectl apply -f k8s/grafana.yml
wait_for_service "grafana"

echo "🔍 Deploying Discovery Service..."
kubectl apply -f k8s/discovery-service.yml
wait_for_service "discovery-service" "core-bank" 240  # Slightly longer for discovery service

echo "📨 Deploying Kafka..."
kubectl apply -f k8s/kafka.yml
wait_for_service "kafka"

# 3. Deploy application services (matching docker-compose dependencies)
echo ""
echo "🏦 Deploying application services..."

echo "💰 Deploying Account Service..."
kubectl apply -f k8s/account-service.yml
wait_for_service "account-service"

echo "👥 Deploying Customer Service..."
kubectl apply -f k8s/customer-service.yml
wait_for_service "customer-service"

echo "💳 Deploying Transaction Service..."
kubectl apply -f k8s/transaction-service.yml
wait_for_service "transaction-service"

echo "🔐 Deploying Authentication Service..."
kubectl apply -f k8s/authentication-service.yml
wait_for_service "authentication-service"

# 4. Deploy load balancer configurations
echo ""
echo "⚖️  Setting up load balancing..."

echo "🌐 Installing NGINX Ingress Controller (if not present)..."
if ! kubectl get ingressclass nginx &>/dev/null; then
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
    
    echo "⏳ Waiting for NGINX Ingress Controller to be ready..."
    kubectl wait --namespace ingress-nginx \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller \
      --timeout=300s
else
    echo "✅ NGINX Ingress Controller already installed"
fi

echo "🔧 Deploying ingress rules and network policies..."
kubectl apply -f k8s/ingress-loadbalancer.yml
kubectl apply -f k8s/network-policy.yml

# 6. Deploy monitoring ServiceMonitors (optional - requires Prometheus Operator)
echo ""
echo "📊 Deploying Prometheus ServiceMonitors (optional)..."
if kubectl get crd servicemonitors.monitoring.coreos.com &>/dev/null; then
    echo "✅ Prometheus Operator CRDs found, deploying ServiceMonitors..."
    kubectl apply -f k8s/prometheus-servicemonitors.yml
    echo "✅ ServiceMonitors deployed successfully"
else
    echo "⚠️ Prometheus Operator CRDs not found. Skipping ServiceMonitors."
    echo "   To enable metrics collection, install Prometheus Operator first:"
    echo "   kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/bundle.yaml"
fi

# 7. Show deployment status
echo ""
echo "✅ All services deployed successfully with load balancing!"
echo ""
echo "🔍 Deployment Status:"
kubectl get deployments -n $NAMESPACE

echo ""
echo "🔍 Pod Status:"
kubectl get pods -n $NAMESPACE

echo ""
echo "🔍 Service Status:"
kubectl get services -n $NAMESPACE

echo ""
echo "🔍 HPA Status:"
kubectl get hpa -n $NAMESPACE

echo ""
echo "🔍 Ingress Status:"
kubectl get ingress -n $NAMESPACE

echo ""
echo "🔍 PVC Status:"
kubectl get pvc -n $NAMESPACE

echo ""
echo "🌐 Load Balanced Access Points:"
echo "================================"
echo "External Access (via Ingress):"
echo "  - Account Service: http://account.core-bank.local"
echo "  - Transaction Service: http://transaction.core-bank.local"
echo "  - Customer Service: http://customer.core-bank.local"
echo "  - Authentication Service: http://auth.core-bank.local"
echo "  - Discovery Service: http://discovery.core-bank.local"
echo "  - Grafana: http://grafana.core-bank.local"
echo "  - Prometheus: http://prometheus.core-bank.local"
echo ""
echo "Direct Access (via port-forward):"
echo "  - Discovery Service: kubectl port-forward svc/discovery-service 8761:8761 -n core-bank"
echo "  - Account Service: kubectl port-forward svc/account-service 8081:8081 -n core-bank"
echo "  - Transaction Service: kubectl port-forward svc/transaction-service 8082:8082 -n core-bank"
echo "  - Customer Service: kubectl port-forward svc/customer-service 8083:8083 -n core-bank"
echo "  - Authentication Service: kubectl port-forward svc/authentication-service 8084:8084 -n core-bank"
echo "  - Prometheus: kubectl port-forward svc/prometheus 9090:9090 -n core-bank"
echo "  - Grafana: kubectl port-forward svc/grafana 3000:3000 -n core-bank"
echo ""
echo "📋 Grafana Credentials:"
echo "  - Username: myuser"
echo "  - Password: mypassword"
echo ""
echo "⚖️  Load Balancing Features:"
echo "  - Account Service: 3 replicas with HPA (2-10 pods)"
echo "  - Transaction Service: 3 replicas with HPA (2-10 pods)"
echo "  - Customer Service: 2 replicas with HPA (1-5 pods)"
echo "  - Authentication Service: 2 replicas with HPA (1-5 pods)"
echo ""
echo "🔧 Management Commands:"
echo "  - Scale services: ./load-balancer.sh scale <service> <replicas>"
echo "  - View status: ./load-balancer.sh status"
echo "  - Test load balancing: ./load-balancer.sh test-lb <service> <port>"
echo "  - Auto-scale all: ./load-balancer.sh auto-scale"
echo ""
echo "🔍 Setup hosts file for local testing:"
echo "  ./load-balancer.sh setup-hosts"
echo ""
echo "🎯 Core Bank is now running on Kubernetes with Load Balancing!"

# Optional: Show resource usage
echo ""
echo "📊 Resource Usage (if metrics-server is installed):"
kubectl top pods -n core-bank 2>/dev/null || echo "   (metrics-server not available)"
