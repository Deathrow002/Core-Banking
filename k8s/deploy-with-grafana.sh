#!/bin/bash

# Core Bank System - Kubernetes Deployment with Grafana Dashboard Setup
# This script deploys the entire core banking system to Kubernetes with monitoring

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

# Check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
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
    kubectl apply -f namespace.yml
    
    # Deploy PostgreSQL
    print_info "Deploying PostgreSQL..."
    kubectl apply -f postgres.yml
    wait_for_service "postgres" "$NAMESPACE" 120
    
    # Deploy Redis
    print_info "Deploying Redis..."
    kubectl apply -f redis.yml
    wait_for_service "redis" "$NAMESPACE" 120
    
    # Deploy Kafka (with Zookeeper)
    print_info "Deploying Kafka and Zookeeper..."
    kubectl apply -f zookeeper.yml
    wait_for_service "zookeeper" "$NAMESPACE" 120
    
    kubectl apply -f kafka.yml
    wait_for_service "kafka" "$NAMESPACE" 180
    
    print_success "Infrastructure services deployed"
    echo ""
}

# Deploy monitoring stack
deploy_monitoring() {
    print_step "Deploying monitoring services..."
    
    # Deploy Prometheus
    print_info "Deploying Prometheus..."
    kubectl apply -f prometheus.yml
    wait_for_service "prometheus" "$NAMESPACE" 120
    
    # Deploy Grafana
    print_info "Deploying Grafana..."
    kubectl apply -f grafana.yml
    wait_for_service "grafana" "$NAMESPACE" 120
    
    print_success "Monitoring services deployed"
    echo ""
}

# Deploy core banking services
deploy_core_services() {
    print_step "Deploying core banking services..."
    
    # Deploy Discovery Service
    print_info "Deploying Discovery Service..."
    kubectl apply -f discovery-service.yml
    wait_for_service "discovery-service" "$NAMESPACE" 180
    
    # Deploy Authentication Service
    print_info "Deploying Authentication Service..."
    kubectl apply -f authentication-service.yml
    wait_for_service "authentication-service" "$NAMESPACE" 120
    
    # Deploy Account Service
    print_info "Deploying Account Service..."
    kubectl apply -f account-service.yml
    wait_for_service "account-service" "$NAMESPACE" 120
    
    # Deploy Customer Service
    print_info "Deploying Customer Service..."
    kubectl apply -f customer-service.yml
    wait_for_service "customer-service" "$NAMESPACE" 120
    
    # Deploy Transaction Service
    print_info "Deploying Transaction Service..."
    kubectl apply -f transaction-service.yml
    wait_for_service "transaction-service" "$NAMESPACE" 120
    
    print_success "Core banking services deployed"
    echo ""
}

# Wait for service to be ready
wait_for_service() {
    local service_name=$1
    local namespace=${2:-$NAMESPACE}
    local timeout=${3:-180}
    
    print_info "Waiting for $service_name to be ready..."
    kubectl wait --for=condition=ready pod -l app=$service_name -n $namespace --timeout=${timeout}s
    if [ $? -eq 0 ]; then
        print_success "$service_name is ready"
    else
        print_error "$service_name failed to become ready within ${timeout} seconds"
        echo ""
        print_warning "Debugging information:"
        kubectl get pods -l app=$service_name -n $namespace
        kubectl describe pods -l app=$service_name -n $namespace | tail -10
        echo ""
        return 1
    fi
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
            
            local dashboard_json=$(cat "$dashboard_file")
            local import_payload="{\"dashboard\": $dashboard_json, \"overwrite\": true}"
            
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
    
    cat > setup-k8s-grafana-dashboards.sh << 'EOF'
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
for dashboard in monitoring/grafana/dashboards/*.json; do
    if [ -f "$dashboard" ]; then
        echo "📈 Importing $(basename "$dashboard")..."
        dashboard_json=$(cat "$dashboard")
        curl -s -X POST \
            -H "Content-Type: application/json" \
            -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
            -d "{\"dashboard\": $dashboard_json, \"overwrite\": true}" \
            "$GRAFANA_URL/api/dashboards/db" > /dev/null
    fi
done

echo "✅ Grafana dashboard setup completed!"
echo "🌐 Access Grafana at: $GRAFANA_URL"
echo "🔐 Login: $GRAFANA_USER / $GRAFANA_PASSWORD"
EOF
    
    chmod +x setup-k8s-grafana-dashboards.sh
    print_success "Created setup-k8s-grafana-dashboards.sh script"
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
    
    create_k8s_dashboard_script
    display_deployment_info
    
    print_success "Core Bank System Kubernetes deployment completed successfully!"
    print_info "If dashboards didn't setup automatically, run: ./setup-k8s-grafana-dashboards.sh"
}

# Handle script interruption
trap 'echo -e "\n${RED}⚠️  Deployment interrupted${NC}"; pkill -f "kubectl.*port-forward" 2>/dev/null || true; exit 1' INT TERM

# Run main function with all arguments
main "$@"
