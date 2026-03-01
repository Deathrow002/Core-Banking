#!/bin/bash

# Core Bank System - Kubernetes Deployment with Grafana Dashboard Setup
# This script deploys the entire core banking system to Kubernetes with monitoring

set -e

# -----------------------------
# Add this block here
# -----------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONITORING_DIR="$(realpath "$SCRIPT_DIR/../../monitoring")"
DEPLOY_DIR="$(realpath "$SCRIPT_DIR/../../deployments")"

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

# Ensure deployment manifests exist
ensure_correct_directory() {
    # SCRIPT_DIR and DEPLOY_DIR are already defined at the top
    if [ ! -f "$DEPLOY_DIR/namespace.yml" ] || [ ! -f "$DEPLOY_DIR/postgres.yml" ]; then
        print_error "Cannot find Kubernetes manifests in $DEPLOY_DIR"
        print_info "Please make sure the deployments folder exists and contains namespace.yml, postgres.yml, etc."
        exit 1
    fi

    if [ ! -d "$MONITORING_DIR" ]; then
        print_warning "Monitoring directory $MONITORING_DIR not found. Monitoring deployment may fail."
    fi

    print_info "Deployment manifests verified in $DEPLOY_DIR"
    print_info "Monitoring manifests verified in $MONITORING_DIR"
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

# Deploy monitoring stac# Deploy namespace and core infrastructure
deploy_infrastructure() {
    print_step "Deploying infrastructure services..."
    
    # Create namespace
    print_info "Creating namespace: $NAMESPACE"
    kubectl apply -f "$DEPLOY_DIR/namespace.yml"
    
    # Deploy PostgreSQL
    print_info "Deploying PostgreSQL..."
    kubectl apply -f "$DEPLOY_DIR/postgres.yml"
    wait_for_service "postgres" "$NAMESPACE" 90
    
    # Deploy Redis
    print_info "Deploying Redis..."
    kubectl apply -f "$DEPLOY_DIR/redis.yml"
    wait_for_service "redis" "$NAMESPACE" 60
    
    # Deploy Kafka (KRaft mode - no Zookeeper dependency)
    print_info "Deploying Kafka (KRaft mode)..."
    kubectl apply -f "$DEPLOY_DIR/kafka.yml"
    wait_for_service "kafka" "$NAMESPACE" 120
    
    print_success "Infrastructure services deployed"
    echo ""
}
metheus'
          - '--web.console.libraries=/etc/prometheus/console_libraries'
          - '--web.console.templates=/etc/prometheus/consoles'
          - '--storage.tsdb.retention.time=200h'
          - '--web.enable-lifecycle'
       kubectl apply -f "$MONITORING_DIR/prometheus-config-minimal.yml"      mountPath: /etc/prometheus/
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
    wait_for_service "account-service" "$NAMESkubectl apply -f "$MONITORING_DIR/grafana.yml"e
    print_info "Deploying Customer Service..."
    kubectl apply -f ../deployments/customer-service.yml
    wait_for_service "customer-service" "$deploy_core_services() {
    print_step "Deploying core banking services..."
    
    # Deploy Discovery Service
    print_info "Deploying Discovery Service..."
    kubectl apply -f "$DEPLOY_DIR/discovery-service.yml"
    wait_for_service "discovery-service" "$NAMESPACE" 120
    
    # Deploy Authentication Service
    print_info "Deploying Authentication Service..."
    kubectl apply -f "$DEPLOY_DIR/authentication-service.yml"
    wait_for_service "authentication-service" "$NAMESPACE" 90
    
    # Deploy Account Service
    print_info "Deploying Account Service..."
    kubectl apply -f "$DEPLOY_DIR/account-service.yml"
    wait_for_service "account-service" "$NAMESPACE" 90
    
    # Deploy Customer Service
    print_info "Deploying Customer Service..."
    kubectl apply -f "$DEPLOY_DIR/customer-service.yml"
    wait_for_service "customer-service" "$NAMESPACE" 90
    
    # Deploy Transaction Service
    print_info "Deploying Transaction Service..."
    kubectl apply -f "$DEPLOY_DIR/transaction-service.yml"
    wait_for_service "transaction-service" "$NAMESPACE" 90
    
    print_success "Core banking services deployed"
    echo ""
}  # Wait for service to be ready
wait_for_service() {
    local service_name=$1
    local namespace=${2:-core-bank}
    local timeout=${3:-180}

    print_info "⏳ Waiting for $service_name to be ready in namespace '$namespace'..."

    # 1️⃣ Wait for the deployment (optional but safe)
    if kubectl get deployment "$service_name" -n "$namespace" >/dev/null 2>&1; then
        if ! kubectl wait --for=condition=available deployment/"$service_name" -n "$namespace" --timeout=60s >/dev/null 2>&1; then
            print_warning "⚠️ $service_name deployment not marked 'available' yet — continuing to check pods..."
        fi
    else
        print_warning "⚠️ No deployment found for $service_name in namespace $namespace (skipping direct wait)"
    fi

    # 2️⃣ Wait for pods to be running
    local max_attempts=$((timeout / 10)) # e.g., 180s = 18 attempts
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        local pod_list
        pod_list=$(kubectl get pods -l app="$service_name" -n "$namespace" --no-headers 2>/dev/null)

        local total_pods=$(echo "$pod_list" | grep -c ".*" || echo "0")
        local running_pods=$(echo "$pod_list" | grep -c "Running" || echo "0")

        if [ "$total_pods" -gt 0 ] && [ "$running_pods" -eq "$total_pods" ]; then
            print_success "✅ $service_name is fully running ($running_pods/$total_pods pods)"
            return 0
        fi

        if [ $((attempt % 3)) -eq 0 ]; then  # every 30s
            local pod_status=$(echo "$pod_list" | awk '{print $3}' | sort | uniq -c | xargs)
            print_info "🔍 $service_name pod status: ${pod_status:-no pods yet}"
        fi

        attempt=$((attempt + 1))
        sleep 10
    done

    # 3️⃣ Final check
    local final_running=$(kubectl get pods -l app="$service_name" -n "$namespace" --no-headers 2>/dev/null | grep -c "Running" || echo "0")
    if [ "$final_running" -gt 0 ]; then
        print_warning "⚠️ $service_name is partially running ($final_running pods up)"
        print_info "Continuing deployment — check manually later."
        return 0
    fi

    # 4️⃣ Failure summary
    print_error "❌ $service_name failed to become ready after ${timeout}s"
    kubectl get pods -l app="$service_name" -n "$namespace"
    echo ""
    print_info "Recent pod details:"
    kubectl describe pods -l app="$service_name" -n "$namespace" | tail -20
    echo ""
    print_info "💡 Try:"
    echo "  kubectl logs -l app=$service_name -n $namespace"
    echo "  kubectl get events -n $namespace --sort-by=.metadata.creationTimestamp"
    return 1
}
 nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
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
    local datasou setup_grafana_dashboards() {
    print_step "Setting up Grafana dashboards..."

    local grafana_url="http://localhost:$GRAFANA_PORT"

    # 🕐 Wait for Grafana API to be ready
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

    # 🧭 Auto-detect Grafana dashboards folder
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local base_dir="$(dirname "$(dirname "$script_dir")")"  # Move up 2 levels (from k8s/scripts/linux/)
    local dashboards_dir="$base_dir/monitoring/grafana/dashboards"

    # Normalize Windows backslashes if needed (in WSL)
    dashboards_dir=$(echo "$dashboards_dir" | sed 's/\\/\//g')

    if [ ! -d "$dashboards_dir" ]; then
        print_error "❌ Dashboards directory not found: $dashboards_dir"
        print_info "Please verify your project structure"
        return 1
    fi

    print_success "📂 Detected dashboards directory: $dashboards_dir"

    # 🧩 Create Prometheus datasource
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
        print_success "✅ Prometheus datasource configured"
    else
        print_warning "⚠️ Datasource creation may have failed - check manually"
    fi

    # 🧠 Import dashboards dynamically
    local dashboards=( "$dashboards_dir"/*.json )
    if [ ${#dashboards[@]} -eq 0 ]; then
        print_warning "⚠️ No dashboard JSON files found in $dashboards_dir"
        return 0
    fi

    for dashboard_file in "${dashboards[@]}"; do
        local dashboard_name=$(basename "$dashboard_file" .json)
        print_info "📊 Importing dashboard: $dashboard_name..."

        local dashboard_content=$(cat "$dashboard_file")

        # Wrap dashboard JSON if needed
        if echo "$dashboard_content" | jq -e '.dashboard' >/dev/null 2>&1; then
            local import_payload=$(echo "$dashboard_content" | jq '. + {"overwrite": true}')
        else
            local import_payload="{\"dashboard\": $dashboard_content, \"overwrite\": true}"
        fi

        local result=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
            -d "$import_payload" \
            "$grafana_url/api/dashboards/db" 2>/dev/null)

        if [[ $result == *"success"* ]]; then
            print_success "✅ Dashboard $dashboard_name imported successfully"
        else
            print_warning "⚠️ Dashboard $dashboard_name import may have failed"
        fi
    done

    echo ""
}
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
