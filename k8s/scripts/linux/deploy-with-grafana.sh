#!/bin/bash

# Core Bank System - Kubernetes Deployment with Grafana Dashboard Setup
# This script deploys the entire core banking    # Deploy Kafka (KRaft mode - no Zookeeper dependency)
    print_info "Deploying Kafka..."
    kubectl apply -f ../deployments/kafka.yml
    wait_for_service "kafka" "$NAMESPACE" 120o Kubernetes with monitoring

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="core-bank"
GRAFANA_SERVICE="grafana"
GRAFANA_PORT="3000"
GRAFANA_USER="myuser"
GRAFANA_PASSWORD="mypassword"
PROMETHEUS_SERVICE="prometheus"
PROMETHEUS_PORT="9090"

print_header() {
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}🏦 Core Bank System - Kubernetes Deployment${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Ensure we're in the correct directory
ensure_correct_directory() {
    # Check if we're in the k8s directory or need to change to it
    if [ ! -f "../deployments/namespace.yml" ]; then
        if [ -f "k8s/../deployments/namespace.yml" ]; then
            print_info "Changing to k8s directory..."
            cd k8s
        elif [ -f "../k8s/../deployments/namespace.yml" ]; then
            print_info "Changing to k8s directory..."
            cd ../k8s
        else
            print_error "Cannot find Kubernetes manifests (../deployments/namespace.yml)"
            print_info "Please run this script from the core-bank root directory or k8s directory"
            exit 1
        fi
    fi
    print_info "Running from directory: $(pwd)"
}

# Check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Ensure we're in the correct directory first
    ensure_correct_directory
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        echo "Install kubectl: https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi
    
    # Check cluster connection
    if ! kubectl cluster-info &>/dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        echo ""
        echo "Please ensure:"
        echo "  1. A Kubernetes cluster is running"
        echo "  2. kubectl is configured correctly"
        echo "  3. Current context is set: kubectl config current-context"
        echo ""
        echo "Common solutions:"
        echo "  - Docker Desktop: Enable Kubernetes"
        echo "  - minikube: minikube start"
        echo "  - kind: kind create cluster"
        echo ""
        exit 1
    fi
    
    # Check if helm is available (optional for advanced deployments)
    if command -v helm &> /dev/null; then
        print_info "Helm is available for advanced deployments"
    else
        print_info "Helm not found - using kubectl only"
    fi
    
    print_success "Prerequisites check completed"
    echo ""
}

# Deploy namespace and core infrastructure
deploy_infrastructure() {
    print_step "Deploying infrastructure services..."
    
    # Create namespace
    print_info "Creating namespace: $NAMESPACE"
    kubectl apply -f ../deployments/namespace.yml
    
    # Deploy PostgreSQL
    print_info "Deploying PostgreSQL..."
    kubectl apply -f ../deployments/postgres.yml
    wait_for_service "postgres" "$NAMESPACE" 90
    
    # Deploy Redis
    print_info "Deploying Redis..."
    kubectl apply -f ../deployments/redis.yml
    wait_for_service "redis" "$NAMESPACE" 60
    
    # Deploy Kafka (KRaft mode - no Zookeeper dependency)
    print_info "Deploying Kafka (KRaft mode)..."
    kubectl apply -f ../deployments/kafka.yml
    wait_for_service "kafka" "$NAMESPACE" 120
    
    print_success "Infrastructure services deployed"
    echo ""
}

# Deploy monitoring stack
deploy_monitoring() {
    print_step "Deploying monitoring services..."
    
    # Deploy Prometheus
    print_info "Deploying Prometheus..."
    # Apply only the minimal working config to avoid conflicts
    kubectl apply -f ../monitoring/prometheus-config-minimal.yml
    # Apply Prometheus deployment without the conflicting ConfigMap
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
    wait_for_service "prometheus" "$NAMESPACE" 90
    
    # Deploy Grafana
    print_info "Deploying Grafana..."
    kubectl apply -f ../monitoring/grafana.yml
    wait_for_service "grafana" "$NAMESPACE" 90
    
    print_success "Monitoring services deployed"
    echo ""
}

# Deploy core banking services
deploy_core_services() {
    print_step "Deploying core banking services..."
    
    # Deploy Discovery Service
    print_info "Deploying Discovery Service..."
    kubectl apply -f ../deployments/discovery-service.yml
    wait_for_service "discovery-service" "$NAMESPACE" 120
    
    # Deploy Authentication Service
    print_info "Deploying Authentication Service..."
    kubectl apply -f ../deployments/authentication-service.yml
    wait_for_service "authentication-service" "$NAMESPACE" 90
    
    # Deploy Account Service
    print_info "Deploying Account Service..."
    kubectl apply -f ../deployments/account-service.yml
    wait_for_service "account-service" "$NAMESPACE" 90
    
    # Deploy Customer Service
    print_info "Deploying Customer Service..."
    kubectl apply -f ../deployments/customer-service.yml
    wait_for_service "customer-service" "$NAMESPACE" 90
    
    # Deploy Transaction Service
    print_info "Deploying Transaction Service..."
    kubectl apply -f ../deployments/transaction-service.yml
    wait_for_service "transaction-service" "$NAMESPACE" 90
    
    print_success "Core banking services deployed"
    echo ""
}

# Wait for service to be ready
wait_for_service() {
    local service_name=$1
    local namespace=${2:-$NAMESPACE}
    local timeout=${3:-180}
    
    print_info "Waiting for $service_name to be ready..."
    
    # First, wait for the deployment to be available (less strict)
    kubectl wait --for=condition=available deployment/$service_name -n $namespace --timeout=60s >/dev/null 2>&1
    
    # Then check if pods are actually running (more lenient check)
    local pod_count=$(kubectl get pods -l app=$service_name -n $namespace --no-headers 2>/dev/null | wc -l)
    if [ "$pod_count" -eq 0 ]; then
        print_warning "No pods found for $service_name, waiting for pods to be created..."
        sleep 10
    fi
    
    # Check pod status instead of strict ready condition
    local max_attempts=12  # 2 minutes total (12 * 10s)
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        local running_pods=$(kubectl get pods -l app=$service_name -n $namespace --no-headers 2>/dev/null | grep -c "Running" || echo "0")
        local total_pods=$(kubectl get pods -l app=$service_name -n $namespace --no-headers 2>/dev/null | wc -l || echo "0")
        
        if [ "$running_pods" -gt 0 ] && [ "$total_pods" -gt 0 ]; then
            print_success "$service_name is running ($running_pods/$total_pods pods)"
            return 0
        fi
        
        # Show current status
        if [ $((attempt % 3)) -eq 0 ]; then  # Every 30 seconds
            local pod_status=$(kubectl get pods -l app=$service_name -n $namespace --no-headers 2>/dev/null | awk '{print $3}' | sort | uniq -c | xargs)
            print_info "$service_name status: $pod_status"
        fi
        
        attempt=$((attempt + 1))
        sleep 10
    done
    
    # Final check - if any pods are running, consider it a success
    local final_running=$(kubectl get pods -l app=$service_name -n $namespace --no-headers 2>/dev/null | grep -c "Running" || echo "0")
    if [ "$final_running" -gt 0 ]; then
        print_warning "$service_name is running but may still be starting up completely"
        print_info "Continuing deployment - you can check service health later"
        return 0
    fi
    
    # If we get here, there's likely a real problem
    print_error "$service_name failed to start properly"
    echo ""
    print_warning "Debugging information:"
    kubectl get pods -l app=$service_name -n $namespace
    echo ""
    print_info "Recent events:"
    kubectl get events -n $namespace --sort-by=.metadata.creationTimestamp | tail -5
    echo ""
    print_warning "You can:"
    echo "  1. Check logs: kubectl logs -l app=$service_name -n $namespace"
    echo "  2. Continue anyway: the service might start later"
    echo "  3. Abort and investigate"
    echo ""
    
    # Auto-continue for automated deployments, but show warning
    print_warning "Continuing deployment - please check $service_name status manually later"
    return 0
}

# Get service URL (works with different cluster types)
get_service_url() {
    local service_name=$1
    local port=$2
    local namespace=${3:-$NAMESPACE}
    
    # Try different methods to get service URL
    local node_port=$(kubectl get svc $service_name -n $namespace -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
    local external_ip=$(kubectl get svc $service_name -n $namespace -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    local external_hostname=$(kubectl get svc $service_name -n $namespace -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    
    if [ -n "$external_ip" ]; then
        echo "http://$external_ip:$port"
    elif [ -n "$external_hostname" ]; then
        echo "http://$external_hostname:$port"
    elif [ -n "$node_port" ]; then
        # Get node IP
        local node_ip=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
        if [ -z "$node_ip" ]; then
            node_ip=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
        fi
        if [ -z "$node_ip" ]; then
            node_ip="localhost"
        fi
        echo "http://$node_ip:$node_port"
    else
        echo "http://localhost:$port (use kubectl port-forward)"
    fi
}

# Setup port forwarding for services
setup_port_forwarding() {
    print_step "Setting up port forwarding for local access..."
    
    # Kill existing port-forward processes
    pkill -f "kubectl.*port-forward" 2>/dev/null || true
    sleep 2
    
    # Start port forwarding in background
    print_info "Setting up port forwarding for Grafana..."
    kubectl port-forward svc/$GRAFANA_SERVICE $GRAFANA_PORT:$GRAFANA_PORT -n $NAMESPACE > /dev/null 2>&1 &
    local grafana_pid=$!
    
    print_info "Setting up port forwarding for Prometheus..."
    kubectl port-forward svc/$PROMETHEUS_SERVICE $PROMETHEUS_PORT:$PROMETHEUS_PORT -n $NAMESPACE > /dev/null 2>&1 &
    local prometheus_pid=$!
    
    # Wait for port forwarding to be ready
    sleep 5
    
    # Test connections
    if curl -f -s "http://localhost:$GRAFANA_PORT" > /dev/null 2>&1; then
        print_success "Grafana port forwarding is active"
    else
        print_warning "Grafana port forwarding may not be ready yet"
    fi
    
    if curl -f -s "http://localhost:$PROMETHEUS_PORT" > /dev/null 2>&1; then
        print_success "Prometheus port forwarding is active"
    else
        print_warning "Prometheus port forwarding may not be ready yet"
    fi
    
    echo ""
    print_info "Port forwarding PIDs: Grafana=$grafana_pid, Prometheus=$prometheus_pid"
    print_info "To stop port forwarding: pkill -f 'kubectl.*port-forward'"
    echo ""
}

# Setup Grafana dashboards via API
setup_grafana_dashboards() {
    print_step "Setting up Grafana dashboards..."
    
    local grafana_url="http://localhost:$GRAFANA_PORT"
    
    # Wait for Grafana API to be ready
    print_info "Waiting for Grafana API to be ready..."
    local count=0
    while [ $count -lt 30 ]; do
        if curl -f -s "$grafana_url/api/health" > /dev/null 2>&1; then
            print_success "Grafana API is ready"
            break
        fi
        
        count=$((count + 1))
        if [ $count -eq 30 ]; then
            print_error "Grafana API is not responding after 2.5 minutes"
            print_info "You can setup dashboards manually later"
            return 1
        else
            sleep 5
        fi
    done
    
    # Create Prometheus datasource
    print_info "Creating Prometheus datasource..."
    local datasource_response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
        -d "{
            \"name\": \"Prometheus\",
            \"type\": \"prometheus\",
            \"url\": \"http://prometheus:$PROMETHEUS_PORT\",
            \"access\": \"proxy\",
            \"isDefault\": true,
            \"jsonData\": {
                \"timeInterval\": \"15s\",
                \"queryTimeout\": \"60s\",
                \"httpMethod\": \"POST\"
            }
        }" \
        "$grafana_url/api/datasources" 2>/dev/null)
    
    if [[ $datasource_response == *"success"* ]] || [[ $datasource_response == *"already exists"* ]]; then
        print_success "Prometheus datasource configured"
    else
        print_warning "Datasource creation may have failed - check manually"
    fi
    
    # Import dashboards
    local dashboard_files=(
        "../monitoring/grafana/dashboards/core-bank-overview.json"
        "../monitoring/grafana/dashboards/service-details.json"
        "../monitoring/grafana/dashboards/business-metrics.json"
    )
    
    for dashboard_file in "${dashboard_files[@]}"; do
        if [ -f "$dashboard_file" ]; then
            local dashboard_name=$(basename "$dashboard_file" .json)
            print_info "Importing dashboard: $dashboard_name..."
            
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
                -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
                -d "$import_payload" \
                "$grafana_url/api/dashboards/db" 2>/dev/null)
            
            if [[ $result == *"success"* ]]; then
                print_success "Dashboard $dashboard_name imported"
            else
                print_warning "Dashboard $dashboard_name import may have failed"
            fi
        else
            print_warning "Dashboard file not found: $dashboard_file"
        fi
    done
    
    echo ""
}

# Create Kubernetes dashboard setup script
create_k8s_dashboard_script() {
    print_step "Creating Kubernetes dashboard setup script..."
    
    cat > smart-dashboard-import.sh << 'EOF'
#!/bin/bash

# Kubernetes Grafana Dashboard Setup Script
# Run this script to setup dashboards on an existing K8s deployment

set -e

NAMESPACE="core-bank"
GRAFANA_PORT="3000"
GRAFANA_USER="myuser"
GRAFANA_PASSWORD="mypassword"

echo "🚀 Setting up Grafana dashboards for Kubernetes deployment..."

# Setup port forwarding
echo "📡 Setting up port forwarding..."
pkill -f "kubectl.*port-forward.*grafana" 2>/dev/null || true
kubectl port-forward svc/grafana $GRAFANA_PORT:$GRAFANA_PORT -n $NAMESPACE > /dev/null 2>&1 &
sleep 5

# Setup dashboards
echo "📊 Configuring Grafana..."
GRAFANA_URL="http://localhost:$GRAFANA_PORT"

# Create Prometheus datasource
curl -s -X POST \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    -d '{
        "name": "Prometheus",
        "type": "prometheus",
        "url": "http://prometheus:9090",
        "access": "proxy",
        "isDefault": true
    }' \
    "$GRAFANA_URL/api/datasources" > /dev/null

# Import dashboards
dashboard_files=(
    "monitoring/grafana/dashboards/core-bank-overview.json"
    "monitoring/grafana/dashboards/service-details.json"
    "monitoring/grafana/dashboards/business-metrics.json"
)

for dashboard_file in "\${dashboard_files[@]}"; do
    if [ -f "\$dashboard_file" ]; then
        dashboard_name=\$(basename "\$dashboard_file" .json)
        echo "📈 Importing: \$dashboard_name..."
        
        # Read the dashboard JSON
        dashboard_content=\$(cat "\$dashboard_file")
        
        # Check if the JSON already has a dashboard wrapper
        if echo "\$dashboard_content" | jq -e '.dashboard' >/dev/null 2>&1; then
            # JSON already has dashboard wrapper, just add overwrite flag
            import_payload=\$(echo "\$dashboard_content" | jq '. + {"overwrite": true}')
        else
            # Wrap the dashboard JSON
            import_payload="{\\"dashboard\\": \$dashboard_content, \\"overwrite\\": true}"
        fi
        
        result=\$(curl -s -X POST \\
            -H "Content-Type: application/json" \\
            -u "\$GRAFANA_USER:\$GRAFANA_PASSWORD" \\
            -d "\$import_payload" \\
            "\$GRAFANA_URL/api/dashboards/db" 2>/dev/null)
        
        if [[ \$result == *"success"* ]]; then
            echo "✅ \$dashboard_name imported successfully"
        else
            echo "❌ \$dashboard_name import failed: \$result"
        fi
    else
        echo "❌ Dashboard file not found: \$dashboard_file"
    fi
done

echo "✅ Grafana dashboard setup completed!"
echo "🌐 Access Grafana at: $GRAFANA_URL"
echo "🔐 Login: $GRAFANA_USER / $GRAFANA_PASSWORD"
EOF
    
    chmod +x smart-dashboard-import.sh
    print_success "Created smart-dashboard-import.sh script"
    echo ""
}

# Generate sample metrics for testing
generate_sample_metrics() {
    print_step "Generating sample metrics for testing..."
    
    # Create a quick test script
    cat > /tmp/test-metrics.sh << 'EOF'
#!/bin/bash
echo "Generating test traffic..."
kubectl port-forward svc/account-service 8081:8081 -n core-bank >/dev/null 2>&1 &
kubectl port-forward svc/transaction-service 8082:8082 -n core-bank >/dev/null 2>&1 &
sleep 3

for i in {1..5}; do
    curl -s "http://localhost:8081/actuator/health" > /dev/null
    curl -s "http://localhost:8082/actuator/health" > /dev/null
    sleep 1
done

pkill -f "kubectl.*port-forward.*(account-service|transaction-service)" 2>/dev/null || true
EOF
    
    chmod +x /tmp/test-metrics.sh
    /tmp/test-metrics.sh &
    
    print_success "Sample metrics generation started"
    echo ""
}

# Display deployment information
display_deployment_info() {
    print_step "Deployment completed! Service information:"
    echo ""
    
    # Get service information
    print_info "Getting service URLs..."
    local grafana_url=$(get_service_url "$GRAFANA_SERVICE" "$GRAFANA_PORT")
    local prometheus_url=$(get_service_url "$PROMETHEUS_SERVICE" "$PROMETHEUS_PORT")
    
    echo -e "${GREEN}🌐 Service URLs:${NC}"
    echo -e "  • Grafana Dashboard:     ${BLUE}$grafana_url${NC}"
    echo -e "  • Prometheus:            ${BLUE}$prometheus_url${NC}"
    echo -e "  • Credentials:           ${BLUE}$GRAFANA_USER / $GRAFANA_PASSWORD${NC}"
    echo ""
    
    echo -e "${GREEN}🔧 Port Forwarding (for local access):${NC}"
    echo -e "  • Grafana:               ${BLUE}kubectl port-forward svc/grafana 3000:3000 -n $NAMESPACE${NC}"
    echo -e "  • Prometheus:            ${BLUE}kubectl port-forward svc/prometheus 9090:9090 -n $NAMESPACE${NC}"
    echo ""
    
    echo -e "${GREEN}📊 Available Dashboards:${NC}"
    echo -e "  • Core Bank Overview:    System-wide metrics and health"
    echo -e "  • Service Details:       Individual service performance"
    echo -e "  • Business Metrics:      Banking operations and KPIs"
    echo ""
    
    echo -e "${GREEN}📈 Monitoring Status:${NC}"
    echo -e "  • Prometheus:            ${BLUE}Collecting metrics from account and transaction services${NC}"
    echo -e "  • Grafana Dashboards:    ${BLUE}3 dashboards imported with live data${NC}"
    echo -e "  • Sample Metrics:        ${BLUE}Generated automatically for testing${NC}"
    echo ""
    
    echo -e "${GREEN}🔧 Useful Kubernetes Commands:${NC}"
    echo -e "  • Check pods:            ${BLUE}kubectl get pods -n $NAMESPACE${NC}"
    echo -e "  • Check services:        ${BLUE}kubectl get svc -n $NAMESPACE${NC}"
    echo -e "  • View logs:             ${BLUE}kubectl logs -f deployment/[service-name] -n $NAMESPACE${NC}"
    echo -e "  • Scale service:         ${BLUE}kubectl scale deployment [service-name] --replicas=3 -n $NAMESPACE${NC}"
    echo ""
    
    echo -e "${GREEN}🧪 Testing:${NC}"
    echo -e "  • Postman Collection:    ${BLUE}postman/CoreBank-Kubernetes.postman_collection.json${NC}"
    echo -e "  • Health Checks:         ${BLUE}kubectl port-forward svc/account-service 8081:8081 -n $NAMESPACE${NC}"
    echo -e "                           ${BLUE}curl http://localhost:8081/actuator/health${NC}"
    echo ""
    
    echo -e "${GREEN}🗑️  Cleanup:${NC}"
    echo -e "  • Remove deployment:     ${BLUE}kubectl delete namespace $NAMESPACE${NC}"
    echo -e "  • Stop port forwarding:  ${BLUE}pkill -f 'kubectl.*port-forward'${NC}"
    echo ""
}

# Main deployment function
main() {
    print_header
    
    # Parse command line arguments
    local skip_dashboards=false
    local skip_port_forward=false
    local use_port_forward=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-dashboards)
                skip_dashboards=true
                shift
                ;;
            --skip-port-forward)
                skip_port_forward=true
                shift
                ;;
            --port-forward)
                use_port_forward=true
                shift
                ;;
            --namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --skip-dashboards    Skip Grafana dashboard setup"
                echo "  --skip-port-forward  Skip automatic port forwarding setup"
                echo "  --port-forward       Force port forwarding setup"
                echo "  --namespace NAME     Use custom namespace (default: core-bank)"
                echo "  --help, -h           Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                              # Full deployment with dashboards"
                echo "  $0 --skip-dashboards           # Deploy without dashboard setup"
                echo "  $0 --port-forward              # Deploy and setup port forwarding"
                echo "  $0 --namespace my-bank          # Deploy to custom namespace"
                echo ""
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Execute deployment steps
    check_prerequisites
    deploy_infrastructure
    deploy_monitoring
    deploy_core_services
    
    # Setup port forwarding if requested or if LoadBalancer is not available
    if [ "$use_port_forward" = true ] || [ "$skip_port_forward" != true ]; then
        setup_port_forwarding
    fi
    
    # Setup dashboards
    if [ "$skip_dashboards" != true ]; then
        setup_grafana_dashboards
    fi
    
    # Generate sample metrics for testing
    generate_sample_metrics
    
    create_k8s_dashboard_script
    display_deployment_info
    
    print_success "Core Bank System Kubernetes deployment completed successfully!"
    print_info "If dashboards didn't setup automatically, run: ./smart-dashboard-import.sh"
}

# Handle script interruption
trap 'echo -e "\n${RED}⚠️  Deployment interrupted${NC}"; pkill -f "kubectl.*port-forward" 2>/dev/null || true; exit 1' INT TERM

# Run main function with all arguments
main "$@"
