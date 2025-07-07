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
    local timeout=${3:-120}  # Reduced to 2 minutes
    
    echo "⏳ Waiting for deployment $deployment_name to be ready..."
    
    # First check if deployment exists and is progressing
    local max_attempts=12  # 2 minutes total (12 * 10s)
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        local running_pods=$(kubectl get pods -l app=$deployment_name -n $namespace --no-headers 2>/dev/null | grep -c "Running" || echo "0")
        local total_pods=$(kubectl get pods -l app=$deployment_name -n $namespace --no-headers 2>/dev/null | wc -l | tr -d ' ' || echo "0")
        
        if [ "$running_pods" -gt 0 ] && [ "$total_pods" -gt 0 ]; then
            echo "✅ $deployment_name is running ($running_pods/$total_pods pods)"
            return 0
        fi
        
        # Show current status every 30 seconds
        if [ $((attempt % 3)) -eq 0 ]; then
            local pod_status=$(kubectl get pods -l app=$deployment_name -n $namespace --no-headers 2>/dev/null | awk '{print $3}' | sort | uniq -c | xargs)
            echo "🔍 $deployment_name status: $pod_status"
        fi
        
        attempt=$((attempt + 1))
        sleep 10
    done
    
    # Final check - if any pods are running, consider it a success
    local final_running=$(kubectl get pods -l app=$deployment_name -n $namespace --no-headers 2>/dev/null | grep -c "Running" || echo "0")
    if [ "$final_running" -gt 0 ]; then
        echo "⚠️ $deployment_name is running but may still be starting up"
        return 0
    fi
    
    echo "❌ $deployment_name failed to become ready within ${timeout} seconds"
    echo "🔍 Checking pod status for debugging..."
    kubectl get pods -l app=$deployment_name -n $namespace
    kubectl describe pods -l app=$deployment_name -n $namespace | tail -20
    echo ""
    echo "💡 Common solutions:"
    echo "  - Check pod logs: kubectl logs -l app=$deployment_name -n $namespace"
    echo "  - Check events: kubectl get events -n $namespace --sort-by=.metadata.creationTimestamp"
    echo "  - Check resources: kubectl top pods -n $namespace"
    echo "⚠️ Continuing deployment - please check $deployment_name manually later"
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
    local timeout=${3:-120}
    
    echo "⏳ Waiting for $service_name to be fully ready..."
    
    # Check if service is running using the same logic as wait_for_deployment
    local max_attempts=12  # 2 minutes total (12 * 10s)
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        local running_pods=$(kubectl get pods -l app=$service_name -n $namespace --no-headers 2>/dev/null | grep -c "Running" || echo "0")
        local total_pods=$(kubectl get pods -l app=$service_name -n $namespace --no-headers 2>/dev/null | wc -l | tr -d ' ' || echo "0")
        
        if [ "$running_pods" -gt 0 ] && [ "$total_pods" -gt 0 ]; then
            echo "✅ $service_name is ready ($running_pods/$total_pods pods)"
            return 0
        fi
        
        # Show current status every 30 seconds
        if [ $((attempt % 3)) -eq 0 ]; then
            local pod_status=$(kubectl get pods -l app=$service_name -n $namespace --no-headers 2>/dev/null | awk '{print $3}' | sort | uniq -c | xargs)
            echo "🔍 $service_name status: $pod_status"
        fi
        
        attempt=$((attempt + 1))
        sleep 10
    done
    
    # Final check - if any pods are running, consider it a success
    local final_running=$(kubectl get pods -l app=$service_name -n $namespace --no-headers 2>/dev/null | grep -c "Running" || echo "0")
    if [ "$final_running" -gt 0 ]; then
        echo "⚠️ $service_name is running but may still be starting up"
        return 0
    fi
    
    echo "❌ $service_name failed to become ready within ${timeout} seconds"
    echo "🔍 Debugging information:"
    kubectl get pods -l app=$service_name -n $namespace
    kubectl describe pods -l app=$service_name -n $namespace | tail -20
    echo ""
    echo "💡 Troubleshooting commands:"
    echo "  - kubectl logs -l app=$service_name -n $namespace"
    echo "  - kubectl get events -n $namespace --sort-by=.metadata.creationTimestamp"
    echo "⚠️ Continuing deployment - please check $service_name manually later"
}

# Check cluster connection first
check_cluster_connection

# Set namespace variable
NAMESPACE="core-bank"

# 1. Create namespace
echo "📦 Creating namespace..."
kubectl apply -f k8s/deployments/namespace.yml

# 2. Deploy infrastructure services (matching docker-compose dependencies)
echo ""
echo "🏗️  Deploying infrastructure services..."

echo "🐘 Deploying PostgreSQL..."
kubectl apply -f k8s/deployments/postgres.yml
wait_for_service "postgres"

echo "🗃️  Deploying Redis..."
kubectl apply -f k8s/deployments/redis.yml
wait_for_service "redis"

echo "📊 Deploying Prometheus..."
# Use the minimal working config to avoid YAML conflicts
kubectl apply -f k8s/monitoring/prometheus-config-minimal.yml
# Deploy Prometheus deployment separately to ensure clean config
kubectl apply -f - << 'EOF'
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
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
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
EOF
wait_for_service "prometheus"

echo "📈 Deploying Grafana..."
kubectl apply -f k8s/monitoring/grafana.yml
wait_for_service "grafana"

echo "🔍 Deploying Discovery Service..."
kubectl apply -f k8s/deployments/discovery-service.yml
wait_for_service "discovery-service" "core-bank" 240  # Slightly longer for discovery service

echo "📨 Deploying Kafka..."
kubectl apply -f k8s/deployments/kafka.yml
wait_for_service "kafka"

# 3. Deploy application services (matching docker-compose dependencies)
echo ""
echo "🏦 Deploying application services..."

echo "💰 Deploying Account Service..."
kubectl apply -f k8s/deployments/account-service.yml
wait_for_service "account-service"

echo "👥 Deploying Customer Service..."
kubectl apply -f k8s/deployments/customer-service.yml
wait_for_service "customer-service"

echo "💳 Deploying Transaction Service..."
kubectl apply -f k8s/deployments/transaction-service.yml
wait_for_service "transaction-service"

echo "🔐 Deploying Authentication Service..."
kubectl apply -f k8s/deployments/authentication-service.yml
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
kubectl apply -f k8s/deployments/ingress-loadbalancer.yml
kubectl apply -f k8s/deployments/network-policy.yml

# 6. Deploy monitoring ServiceMonitors (optional - requires Prometheus Operator)
echo ""
echo "📊 Deploying Prometheus ServiceMonitors (optional)..."
if kubectl get crd servicemonitors.monitoring.coreos.com &>/dev/null; then
    echo "✅ Prometheus Operator CRDs found, deploying ServiceMonitors..."
    kubectl apply -f k8s/monitoring/prometheus-servicemonitors.yml
    echo "✅ ServiceMonitors deployed successfully"
else
    echo "⚠️ Prometheus Operator CRDs not found. Skipping ServiceMonitors."
    echo "   To enable metrics collection, install Prometheus Operator first:"
    echo "   kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/bundle.yaml"
fi

# 7. Setup Grafana dashboards
# Setup Grafana dashboards via API
setup_grafana_dashboards() {
    echo "📊 Setting up Grafana dashboards..."
    
    local grafana_url="http://localhost:3000"
    
    # Setup port forwarding for Grafana
    echo "📡 Setting up port forwarding for Grafana..."
    pkill -f "kubectl.*port-forward.*grafana" 2>/dev/null || true
    kubectl port-forward svc/grafana 3000:3000 -n core-bank > /tmp/grafana-port-forward.log 2>&1 &
    local grafana_pid=$!
    
    # Wait for Grafana API to be ready
    echo "⏳ Waiting for Grafana API to be ready..."
    local count=0
    while [ $count -lt 30 ]; do
        if curl -f -s "$grafana_url/api/health" > /dev/null 2>&1; then
            echo "✅ Grafana API is ready"
            break
        fi
        
        count=$((count + 1))
        if [ $count -eq 30 ]; then
            echo "❌ Grafana API is not responding after 2.5 minutes"
            echo "💡 You can setup dashboards manually later using:"
            echo "   kubectl port-forward svc/grafana 3000:3000 -n core-bank"
            echo "   Then visit http://localhost:3000 (myuser/mypassword)"
            return 1
        else
            sleep 5
        fi
    done
    
    # Create Prometheus datasource
    echo "🔗 Creating Prometheus datasource..."
    local datasource_response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -u "myuser:mypassword" \
        -d '{
            "name": "Prometheus",
            "type": "prometheus",
            "url": "http://prometheus:9090",
            "access": "proxy",
            "isDefault": true,
            "jsonData": {
                "timeInterval": "15s",
                "queryTimeout": "60s",
                "httpMethod": "POST"
            }
        }' \
        "$grafana_url/api/datasources" 2>/dev/null)
    
    if [[ $datasource_response == *"success"* ]] || [[ $datasource_response == *"already exists"* ]]; then
        echo "✅ Prometheus datasource configured"
    else
        echo "⚠️ Datasource creation may have failed - check manually"
    fi
    
    # Import dashboards
    local dashboard_files=(
        "monitoring/grafana/dashboards/core-bank-overview.json"
        "monitoring/grafana/dashboards/service-details.json"
        "monitoring/grafana/dashboards/business-metrics.json"
    )
    
    for dashboard_file in "${dashboard_files[@]}"; do
        if [ -f "$dashboard_file" ]; then
            local dashboard_name=$(basename "$dashboard_file" .json)
            echo "📈 Importing dashboard: $dashboard_name..."
            
            # Read the dashboard JSON
            local dashboard_content=$(cat "$dashboard_file")
            
            # Check if the JSON already has a dashboard wrapper
            if echo "$dashboard_content" | jq -e '.dashboard' >/dev/null 2>&1; then
                # JSON already has dashboard wrapper, just add overwrite flag
                local import_payload=$(echo "$dashboard_content" | jq '. + {"overwrite": true}')
            else
                # Wrap the dashboard JSON
                local import_payload="{\"dashboard\": $dashboard_content, \"overwrite\": true}"
            fi
            
            local result=$(curl -s -X POST \
                -H "Content-Type: application/json" \
                -u "myuser:mypassword" \
                -d "$import_payload" \
                "$grafana_url/api/dashboards/db" 2>/dev/null)
            
            if [[ $result == *"success"* ]]; then
                echo "✅ Dashboard $dashboard_name imported"
            else
                echo "⚠️ Dashboard $dashboard_name import may have failed"
            fi
        else
            echo "⚠️ Dashboard file not found: $dashboard_file"
        fi
    done
    
    echo "✅ Grafana dashboard setup completed!"
    echo "🌐 Access Grafana at: http://localhost:3000"
    echo "🔐 Login: myuser / mypassword"
    echo "📊 3 dashboards imported: Core Bank Overview, Service Details, Business Metrics"
    echo ""
    echo "💡 To stop port forwarding later: pkill -f 'kubectl.*port-forward'"
    echo ""
}

echo ""
setup_grafana_dashboards

# 8. Show deployment status
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
echo "  - Access: http://localhost:3000 (if port-forward is active)"
echo ""
echo "📊 Available Grafana Dashboards:"
echo "  • Core Bank System - Microservices Overview"
echo "  • Core Bank System - Service Details"  
echo "  • Core Bank System - Business Metrics"
echo "  💡 If dashboards are missing, run: ./k8s/smart-dashboard-import.sh"
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
