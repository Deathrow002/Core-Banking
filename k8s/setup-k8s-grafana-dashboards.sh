#!/bin/bash

# Kubernetes Grafana Dashboard Setup Script
# Run this script to setup dashboards on an existing K8s deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="core-bank"
GRAFANA_PORT="3000"
GRAFANA_USER="myuser"
GRAFANA_PASSWORD="mypassword"
PROMETHEUS_PORT="9090"

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

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}📊 Kubernetes Grafana Dashboard Setup${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if namespace exists
if ! kubectl get namespace $NAMESPACE &>/dev/null; then
    print_error "Namespace '$NAMESPACE' does not exist"
    echo "Please deploy the core bank system first:"
    echo "  ./deploy-with-grafana.sh"
    exit 1
fi

# Check if Grafana is running
if ! kubectl get deployment grafana -n $NAMESPACE &>/dev/null; then
    print_error "Grafana deployment not found in namespace '$NAMESPACE'"
    echo "Please deploy Grafana first"
    exit 1
fi

print_step "Setting up port forwarding for Grafana and Prometheus..."

# Kill existing port-forward processes
pkill -f "kubectl.*port-forward.*grafana" 2>/dev/null || true
pkill -f "kubectl.*port-forward.*prometheus" 2>/dev/null || true
sleep 2

# Setup port forwarding
print_info "Starting port forwarding for Grafana on port $GRAFANA_PORT..."
kubectl port-forward svc/grafana $GRAFANA_PORT:$GRAFANA_PORT -n $NAMESPACE > /dev/null 2>&1 &
GRAFANA_PID=$!

print_info "Starting port forwarding for Prometheus on port $PROMETHEUS_PORT..."
kubectl port-forward svc/prometheus $PROMETHEUS_PORT:$PROMETHEUS_PORT -n $NAMESPACE > /dev/null 2>&1 &
PROMETHEUS_PID=$!

# Wait for port forwarding to be active
sleep 5

print_step "Configuring Grafana datasource and dashboards..."

GRAFANA_URL="http://localhost:$GRAFANA_PORT"

# Wait for Grafana to be ready
print_info "Waiting for Grafana to be ready..."
count=0
while [ $count -lt 24 ]; do
    if curl -f -s "$GRAFANA_URL/api/health" > /dev/null 2>&1; then
        print_success "Grafana is ready"
        break
    fi
    
    count=$((count + 1))
    if [ $count -eq 24 ]; then
        print_error "Grafana is not responding after 2 minutes"
        print_info "Check if Grafana pod is running: kubectl get pods -l app=grafana -n $NAMESPACE"
        exit 1
    else
        sleep 5
    fi
done

# Create/update Prometheus datasource
print_info "Creating Prometheus datasource..."
datasource_response=$(curl -s -X POST \
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
    "$GRAFANA_URL/api/datasources" 2>/dev/null)

if [[ $datasource_response == *"success"* ]] || [[ $datasource_response == *"already exists"* ]]; then
    print_success "Prometheus datasource configured"
elif [[ $datasource_response == *"already exists"* ]]; then
    print_success "Prometheus datasource already exists"
else
    print_error "Failed to create Prometheus datasource"
    echo "Response: $datasource_response"
fi

# Import dashboards
print_step "Importing Grafana dashboards..."

dashboard_files=(
    "../monitoring/grafana/dashboards/core-bank-overview.json"
    "../monitoring/grafana/dashboards/service-details.json" 
    "../monitoring/grafana/dashboards/business-metrics.json"
)

imported_count=0
total_count=${#dashboard_files[@]}

for dashboard_file in "${dashboard_files[@]}"; do
    if [ -f "$dashboard_file" ]; then
        dashboard_name=$(basename "$dashboard_file" .json)
        print_info "Importing dashboard: $dashboard_name..."
        
        dashboard_json=$(cat "$dashboard_file")
        import_payload="{\"dashboard\": $dashboard_json, \"overwrite\": true}"
        
        result=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
            -d "$import_payload" \
            "$GRAFANA_URL/api/dashboards/db" 2>/dev/null)
        
        if [[ $result == *"success"* ]]; then
            print_success "Dashboard '$dashboard_name' imported successfully"
            imported_count=$((imported_count + 1))
        else
            print_error "Failed to import dashboard '$dashboard_name'"
            echo "Response: $result"
        fi
    else
        print_error "Dashboard file not found: $dashboard_file"
    fi
done

echo ""
print_success "Dashboard setup completed: $imported_count/$total_count dashboards imported"

echo ""
echo -e "${GREEN}🌐 Access Information:${NC}"
echo -e "  • Grafana Dashboard:  ${BLUE}$GRAFANA_URL${NC}"
echo -e "  • Prometheus:         ${BLUE}http://localhost:$PROMETHEUS_PORT${NC}"
echo -e "  • Login Credentials:  ${BLUE}$GRAFANA_USER / $GRAFANA_PASSWORD${NC}"
echo ""

echo -e "${GREEN}📊 Available Dashboards:${NC}"
echo -e "  • Core Bank Overview - System-wide health and performance"
echo -e "  • Service Details    - Individual service metrics"
echo -e "  • Business Metrics   - Banking operations and KPIs"
echo ""

echo -e "${GREEN}🔧 Management:${NC}"
echo -e "  • Stop port forwarding: ${BLUE}pkill -f 'kubectl.*port-forward'${NC}"
echo -e "  • Check pods:           ${BLUE}kubectl get pods -n $NAMESPACE${NC}"
echo -e "  • View Grafana logs:    ${BLUE}kubectl logs deployment/grafana -n $NAMESPACE${NC}"
echo ""

echo -e "${GREEN}🎉 Grafana dashboard setup completed successfully!${NC}"
echo -e "${BLUE}ℹ️  Port forwarding is running in the background (PIDs: Grafana=$GRAFANA_PID, Prometheus=$PROMETHEUS_PID)${NC}"
