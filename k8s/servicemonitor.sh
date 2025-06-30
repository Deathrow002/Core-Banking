#!/bin/bash

# ServiceMonitor Management Script for Prometheus Operator
# This script helps deploy, update, and manage ServiceMonitor resources

set -e

NAMESPACE="core-bank"
SERVICEMONITOR_FILE="k8s/prometheus-servicemonitors.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if Prometheus Operator is installed
check_prometheus_operator() {
    echo "🔍 Checking for Prometheus Operator..."
    
    if kubectl get crd servicemonitors.monitoring.coreos.com &>/dev/null; then
        echo -e "${GREEN}✅ Prometheus Operator CRDs found${NC}"
        return 0
    else
        echo -e "${RED}❌ Prometheus Operator CRDs not found${NC}"
        return 1
    fi
}

# Function to install Prometheus Operator
install_prometheus_operator() {
    echo "📦 Installing Prometheus Operator..."
    kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/bundle.yaml
    
    echo "⏳ Waiting for Prometheus Operator to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus-operator -n default --timeout=300s
    
    echo -e "${GREEN}✅ Prometheus Operator installed successfully${NC}"
}

# Function to deploy ServiceMonitors
deploy_servicemonitors() {
    echo "📊 Deploying ServiceMonitors..."
    
    if [ ! -f "$SERVICEMONITOR_FILE" ]; then
        echo -e "${RED}❌ ServiceMonitor file not found: $SERVICEMONITOR_FILE${NC}"
        exit 1
    fi
    
    kubectl apply -f "$SERVICEMONITOR_FILE"
    echo -e "${GREEN}✅ ServiceMonitors deployed successfully${NC}"
}

# Function to list ServiceMonitors
list_servicemonitors() {
    echo "📋 Current ServiceMonitors in namespace $NAMESPACE:"
    kubectl get servicemonitors -n $NAMESPACE -o wide 2>/dev/null || echo "No ServiceMonitors found"
}

# Function to delete ServiceMonitors
delete_servicemonitors() {
    echo "🗑️  Deleting ServiceMonitors..."
    kubectl delete -f "$SERVICEMONITOR_FILE" 2>/dev/null || echo "ServiceMonitors not found or already deleted"
    echo -e "${GREEN}✅ ServiceMonitors deleted${NC}"
}

# Function to show ServiceMonitor status
show_status() {
    echo "📊 ServiceMonitor Status:"
    echo "========================"
    
    # Check if CRDs exist
    if check_prometheus_operator; then
        # List ServiceMonitors
        list_servicemonitors
        
        echo ""
        echo "🎯 ServiceMonitor Targets:"
        kubectl get servicemonitors -n $NAMESPACE -o json 2>/dev/null | \
            jq -r '.items[] | "\(.metadata.name): \(.spec.selector.matchLabels | to_entries | map("\(.key)=\(.value)") | join(","))"' 2>/dev/null || \
            echo "Unable to parse ServiceMonitor targets (jq not available)"
    else
        echo -e "${YELLOW}⚠️  Prometheus Operator not installed${NC}"
    fi
}

# Function to validate ServiceMonitors
validate_servicemonitors() {
    echo "🔍 Validating ServiceMonitor configuration..."
    
    if [ ! -f "$SERVICEMONITOR_FILE" ]; then
        echo -e "${RED}❌ ServiceMonitor file not found: $SERVICEMONITOR_FILE${NC}"
        exit 1
    fi
    
    # Check basic YAML structure
    echo "📋 Checking YAML structure..."
    local has_apiversion=$(grep -c "apiVersion: monitoring.coreos.com" "$SERVICEMONITOR_FILE")
    local has_kind=$(grep -c "kind: ServiceMonitor" "$SERVICEMONITOR_FILE")
    local has_metadata=$(grep -c "metadata:" "$SERVICEMONITOR_FILE")
    local has_spec=$(grep -c "spec:" "$SERVICEMONITOR_FILE")
    
    if [ $has_apiversion -gt 0 ] && [ $has_kind -gt 0 ] && [ $has_metadata -gt 0 ] && [ $has_spec -gt 0 ]; then
        echo -e "${GREEN}✅ ServiceMonitor YAML structure is valid${NC}"
        echo "  - Found $has_kind ServiceMonitor resources"
        echo "  - All have proper apiVersion (monitoring.coreos.com/v1)"
    else
        echo -e "${RED}❌ ServiceMonitor YAML structure is invalid${NC}"
        echo "  - Expected: apiVersion, kind, metadata, spec sections"
        exit 1
    fi
    
    # Check if target services are defined
    echo "🎯 Checking target service definitions..."
    local services=("account-service" "transaction-service" "customer-service" "authentication-service" "discovery-service")
    
    for service in "${services[@]}"; do
        if grep -q "app: $service" "$SERVICEMONITOR_FILE"; then
            echo -e "  ${GREEN}✅ $service monitor defined${NC}"
        else
            echo -e "  ${YELLOW}⚠️  $service monitor not defined${NC}"
        fi
    done
    
    # Check if cluster is accessible for service validation
    if kubectl cluster-info &>/dev/null; then
        echo ""
        echo "🔗 Checking if target services exist in cluster..."
        for service in "${services[@]}"; do
            if kubectl get service "$service" -n $NAMESPACE &>/dev/null; then
                echo -e "  ${GREEN}✅ Service $service exists${NC}"
            else
                echo -e "  ${RED}❌ Service $service not found${NC}"
            fi
        done
    else
        echo -e "${YELLOW}⚠️  No cluster connection - skipping service existence check${NC}"
    fi
}

# Help function
show_help() {
    echo "ServiceMonitor Management Script"
    echo "==============================="
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  install-operator    Install Prometheus Operator"
    echo "  deploy             Deploy ServiceMonitors"
    echo "  delete             Delete ServiceMonitors"
    echo "  list               List ServiceMonitors"
    echo "  status             Show detailed status"
    echo "  validate           Validate ServiceMonitor configuration"
    echo "  check              Check if Prometheus Operator is installed"
    echo "  help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 check                    # Check if Prometheus Operator is installed"
    echo "  $0 install-operator         # Install Prometheus Operator"
    echo "  $0 deploy                   # Deploy ServiceMonitors"
    echo "  $0 status                   # Show status of all ServiceMonitors"
    echo ""
}

# Main command handling
case "${1:-help}" in
    "install-operator")
        if check_prometheus_operator; then
            echo -e "${YELLOW}⚠️  Prometheus Operator already installed${NC}"
        else
            install_prometheus_operator
        fi
        ;;
    "deploy")
        if check_prometheus_operator; then
            deploy_servicemonitors
        else
            echo -e "${RED}❌ Prometheus Operator not found. Install it first with: $0 install-operator${NC}"
            exit 1
        fi
        ;;
    "delete")
        delete_servicemonitors
        ;;
    "list")
        list_servicemonitors
        ;;
    "status")
        show_status
        ;;
    "validate")
        validate_servicemonitors
        ;;
    "check")
        check_prometheus_operator
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
