#!/bin/bash

# Load Balancer and Scaling Management Script for Core Bank K8s

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NAMESPACE="core-bank"

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to scale a service
scale_service() {
    local service_name=$1
    local replicas=$2
    
    print_info "Scaling $service_name to $replicas replicas..."
    kubectl scale deployment $service_name --replicas=$replicas -n $NAMESPACE
    
    if [ $? -eq 0 ]; then
        print_status "$service_name scaled to $replicas replicas"
    else
        print_error "Failed to scale $service_name"
        exit 1
    fi
}

# Function to show current status
show_status() {
    echo -e "${BLUE}🔍 Current Status:${NC}"
    echo "===================="
    
    echo -e "\n${YELLOW}Deployments:${NC}"
    kubectl get deployments -n $NAMESPACE -o wide
    
    echo -e "\n${YELLOW}Pods:${NC}"
    kubectl get pods -n $NAMESPACE -o wide
    
    echo -e "\n${YELLOW}Services:${NC}"
    kubectl get services -n $NAMESPACE
    
    echo -e "\n${YELLOW}HPA Status:${NC}"
    kubectl get hpa -n $NAMESPACE
    
    echo -e "\n${YELLOW}Pod Disruption Budgets:${NC}"
    kubectl get pdb -n $NAMESPACE
    
    if command -v kubectl &> /dev/null && kubectl top pods -n $NAMESPACE &> /dev/null; then
        echo -e "\n${YELLOW}Resource Usage:${NC}"
        kubectl top pods -n $NAMESPACE
    else
        print_warning "Metrics server not available - cannot show resource usage"
    fi
}

# Function to test load balancing
test_load_balancing() {
    local service_name=$1
    local port=$2
    local requests=${3:-10}
    
    print_info "Testing load balancing for $service_name (port $port) with $requests requests..."
    
    # Port forward in background
    kubectl port-forward svc/$service_name $port:$port -n $NAMESPACE &
    local port_forward_pid=$!
    
    # Wait for port forward to establish
    sleep 3
    
    echo "Making $requests requests to test load distribution..."
    for i in $(seq 1 $requests); do
        response=$(curl -s "http://localhost:$port/actuator/info" 2>/dev/null || echo "failed")
        if [[ "$response" == *"failed"* ]]; then
            echo "❌ Request $i failed"
        else
            echo "✅ Request $i succeeded"
        fi
        sleep 0.5
    done
    
    # Clean up port forward
    kill $port_forward_pid 2>/dev/null || true
    
    print_status "Load balancing test completed for $service_name"
}

# Function to deploy load balancer configurations
deploy_load_balancer() {
    print_info "Deploying load balancer configurations..."
    
    # Deploy ingress controller if not exists
    if ! kubectl get ingressclass nginx &>/dev/null; then
        print_info "Installing NGINX Ingress Controller..."
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
        
        print_info "Waiting for NGINX Ingress Controller to be ready..."
        kubectl wait --namespace ingress-nginx \
          --for=condition=ready pod \
          --selector=app.kubernetes.io/component=controller \
          --timeout=300s
    else
        print_status "NGINX Ingress Controller already installed"
    fi
    
    # Deploy ingress rules
    kubectl apply -f k8s/ingress-loadbalancer.yml
    kubectl apply -f k8s/network-policy.yml
    
    print_status "Load balancer configurations deployed"
}

# Function to setup hosts file entries (for local testing)
setup_hosts() {
    print_info "Setting up local hosts file entries..."
    
    # Get external IP or use localhost for local clusters
    EXTERNAL_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "127.0.0.1")
    
    if [ "$EXTERNAL_IP" = "" ]; then
        EXTERNAL_IP="127.0.0.1"
    fi
    
    echo ""
    print_warning "Add these entries to your /etc/hosts file for local testing:"
    echo "$EXTERNAL_IP account.core-bank.local"
    echo "$EXTERNAL_IP transaction.core-bank.local"
    echo "$EXTERNAL_IP customer.core-bank.local"
    echo "$EXTERNAL_IP auth.core-bank.local"
    echo "$EXTERNAL_IP discovery.core-bank.local"
    echo "$EXTERNAL_IP grafana.core-bank.local"
    echo "$EXTERNAL_IP prometheus.core-bank.local"
    echo ""
    print_info "Or run: sudo bash -c 'cat >> /etc/hosts << EOF"
    echo "$EXTERNAL_IP account.core-bank.local"
    echo "$EXTERNAL_IP transaction.core-bank.local"
    echo "$EXTERNAL_IP customer.core-bank.local"
    echo "$EXTERNAL_IP auth.core-bank.local"
    echo "$EXTERNAL_IP discovery.core-bank.local"
    echo "$EXTERNAL_IP grafana.core-bank.local"
    echo "$EXTERNAL_IP prometheus.core-bank.local"
    echo "EOF'"
}

# Main script logic
case "${1:-}" in
    "status")
        show_status
        ;;
    "scale")
        if [ $# -ne 3 ]; then
            print_error "Usage: $0 scale <service-name> <replicas>"
            print_info "Available services: account-service, transaction-service, customer-service, authentication-service"
            exit 1
        fi
        scale_service $2 $3
        ;;
    "scale-all")
        if [ $# -ne 2 ]; then
            print_error "Usage: $0 scale-all <replicas>"
            exit 1
        fi
        scale_service "account-service" $2
        scale_service "transaction-service" $2
        scale_service "customer-service" $2
        scale_service "authentication-service" $2
        ;;
    "test-lb")
        if [ $# -ne 3 ]; then
            print_error "Usage: $0 test-lb <service-name> <port>"
            print_info "Example: $0 test-lb account-service 8081"
            exit 1
        fi
        test_load_balancing $2 $3
        ;;
    "deploy-lb")
        deploy_load_balancer
        ;;
    "setup-hosts")
        setup_hosts
        ;;
    "auto-scale")
        print_info "Setting up production-ready scaling..."
        scale_service "account-service" 3
        scale_service "transaction-service" 3
        scale_service "customer-service" 2
        scale_service "authentication-service" 2
        print_status "Auto-scaling setup completed"
        ;;
    "stress-test")
        print_info "Running stress test on all services..."
        test_load_balancing "account-service" 8081 20
        test_load_balancing "transaction-service" 8082 20
        test_load_balancing "customer-service" 8083 20
        test_load_balancing "authentication-service" 8084 20
        ;;
    *)
        echo -e "${BLUE}🏦 Core Bank Load Balancer Management${NC}"
        echo "=================================="
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  status                          - Show current deployment status"
        echo "  scale <service> <replicas>      - Scale a specific service"
        echo "  scale-all <replicas>            - Scale all services to same replica count"
        echo "  test-lb <service> <port>        - Test load balancing for a service"
        echo "  deploy-lb                       - Deploy load balancer configurations"
        echo "  setup-hosts                     - Show hosts file entries for local testing"
        echo "  auto-scale                      - Set production-ready scaling (3,3,2,2)"
        echo "  stress-test                     - Run stress test on all services"
        echo ""
        echo "Examples:"
        echo "  $0 scale account-service 5"
        echo "  $0 scale-all 3"
        echo "  $0 test-lb account-service 8081"
        echo "  $0 deploy-lb"
        echo "  $0 auto-scale"
        echo ""
        ;;
esac
