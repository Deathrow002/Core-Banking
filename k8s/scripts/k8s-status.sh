#!/bin/bash

# Kubernetes Deployment Status and Access Guide
# This script shows the current status and provides access information

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

NAMESPACE="core-bank"

print_header() {
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}🏦 Core Bank System - Kubernetes Status${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo ""
}

print_section() {
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}$(printf '=%.0s' $(seq 1 ${#1}))${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_deployment_status() {
    print_section "📊 Deployment Status"
    echo ""
    
    # Check if namespace exists
    if kubectl get namespace $NAMESPACE &>/dev/null; then
        print_success "Namespace '$NAMESPACE' exists"
    else
        print_warning "Namespace '$NAMESPACE' does not exist"
        echo "Run: ./deploy-with-grafana.sh"
        return 1
    fi
    
    # Get all pods
    echo -e "${BLUE}Pod Status:${NC}"
    kubectl get pods -n $NAMESPACE
    echo ""
    
    # Count running pods
    local total_pods=$(kubectl get pods -n $NAMESPACE --no-headers | wc -l)
    local running_pods=$(kubectl get pods -n $NAMESPACE --no-headers | grep "Running" | wc -l)
    
    echo -e "${BLUE}Summary: $running_pods/$total_pods pods are running${NC}"
    
    if [ $running_pods -eq $total_pods ]; then
        print_success "All services are running successfully!"
    else
        print_warning "Some services are not running properly"
        kubectl get pods -n $NAMESPACE | grep -v "Running" | grep -v "NAME" || true
    fi
    echo ""
}

show_service_urls() {
    print_section "🌐 Service Access"
    echo ""
    
    echo -e "${GREEN}Port Forwarding Commands:${NC}"
    echo -e "  • Grafana:               ${BLUE}kubectl port-forward svc/grafana 3000:3000 -n $NAMESPACE${NC}"
    echo -e "  • Prometheus:            ${BLUE}kubectl port-forward svc/prometheus 9090:9090 -n $NAMESPACE${NC}"
    echo -e "  • Discovery Service:     ${BLUE}kubectl port-forward svc/discovery-service 8761:8761 -n $NAMESPACE${NC}"
    echo -e "  • Account Service:       ${BLUE}kubectl port-forward svc/account-service 8081:8081 -n $NAMESPACE${NC}"
    echo -e "  • Customer Service:      ${BLUE}kubectl port-forward svc/customer-service 8083:8083 -n $NAMESPACE${NC}"
    echo -e "  • Transaction Service:   ${BLUE}kubectl port-forward svc/transaction-service 8082:8082 -n $NAMESPACE${NC}"
    echo -e "  • Authentication:        ${BLUE}kubectl port-forward svc/authentication-service 8084:8084 -n $NAMESPACE${NC}"
    echo ""
    
    echo -e "${GREEN}Access URLs (with port forwarding):${NC}"
    echo -e "  • Grafana Dashboard:     ${BLUE}http://localhost:3000${NC} (myuser/mypassword)"
    echo -e "  • Prometheus:            ${BLUE}http://localhost:9090${NC}"
    echo -e "  • Discovery Service:     ${BLUE}http://localhost:8761${NC}"
    echo -e "  • Account API:           ${BLUE}http://localhost:8081${NC}"
    echo -e "  • Customer API:          ${BLUE}http://localhost:8083${NC}"
    echo -e "  • Transaction API:       ${BLUE}http://localhost:8082${NC}"
    echo -e "  • Authentication API:    ${BLUE}http://localhost:8084${NC}"
    echo ""
}

show_grafana_dashboards() {
    print_section "📊 Grafana Dashboards"
    echo ""
    
    # Check if port forwarding is already running
    if pgrep -f "kubectl.*port-forward.*grafana" > /dev/null; then
        print_success "Grafana port forwarding is already active"
        echo -e "  • Access: ${BLUE}http://localhost:3000${NC}"
    else
        print_info "Setting up temporary port forwarding to check dashboards..."
        kubectl port-forward svc/grafana 3000:3000 -n $NAMESPACE > /dev/null 2>&1 &
        local pf_pid=$!
        sleep 3
        
        # Check if Grafana is accessible
        if curl -f -s "http://localhost:3000/api/health" > /dev/null 2>&1; then
            print_success "Grafana is accessible at http://localhost:3000"
        else
            print_warning "Grafana port forwarding setup failed"
        fi
        
        # Kill the temporary port forward
        kill $pf_pid 2>/dev/null || true
    fi
    
    echo ""
    echo -e "${GREEN}Available Dashboards:${NC}"
    echo -e "  📈 ${BLUE}Core Bank Overview${NC}    - System-wide health and performance metrics"
    echo -e "  🔍 ${BLUE}Service Details${NC}       - Individual microservice performance and JVM metrics"
    echo -e "  💰 ${BLUE}Business Metrics${NC}      - Banking operations, transactions, and business KPIs"
    echo ""
    
    echo -e "${GREEN}Dashboard Features:${NC}"
    echo -e "  • Real-time monitoring of all microservices"
    echo -e "  • Resource usage (CPU, Memory, Network)"
    echo -e "  • Response times and error rates"
    echo -e "  • Database connection pools and performance"
    echo -e "  • Business transaction volumes and success rates"
    echo ""
}

show_testing_info() {
    print_section "🧪 Testing & Validation"
    echo ""
    
    echo -e "${GREEN}Health Checks:${NC}"
    echo -e "  • Check all pods:        ${BLUE}kubectl get pods -n $NAMESPACE${NC}"
    echo -e "  • Service endpoints:     ${BLUE}kubectl get svc -n $NAMESPACE${NC}"
    echo -e "  • API health check:      ${BLUE}curl http://localhost:8081/actuator/health${NC}"
    echo ""
    
    echo -e "${GREEN}API Testing:${NC}"
    echo -e "  • Postman Collection:    ${BLUE}../postman/CoreBank-Kubernetes.postman_collection.json${NC}"
    echo -e "  • Authentication Test:   ${BLUE}curl -X POST http://localhost:8084/auth/login${NC}"
    echo -e "  • Account Service Test:  ${BLUE}curl http://localhost:8081/accounts${NC}"
    echo ""
    
    echo -e "${GREEN}Monitoring Validation:${NC}"
    echo -e "  • Prometheus Targets:    ${BLUE}http://localhost:9090/targets${NC}"
    echo -e "  • Service Metrics:       ${BLUE}http://localhost:8081/actuator/prometheus${NC}"
    echo -e "  • Grafana Data Sources:  ${BLUE}http://localhost:3000/datasources${NC}"
    echo ""
}

show_management_commands() {
    print_section "🔧 Management Commands"
    echo ""
    
    echo -e "${GREEN}Scaling Services:${NC}"
    echo -e "  • Scale up:              ${BLUE}kubectl scale deployment account-service --replicas=3 -n $NAMESPACE${NC}"
    echo -e "  • Scale down:            ${BLUE}kubectl scale deployment account-service --replicas=1 -n $NAMESPACE${NC}"
    echo -e "  • Auto-scaling:          ${BLUE}kubectl autoscale deployment account-service --cpu-percent=70 --min=1 --max=5 -n $NAMESPACE${NC}"
    echo ""
    
    echo -e "${GREEN}Logging & Debugging:${NC}"
    echo -e "  • Service logs:          ${BLUE}kubectl logs -f deployment/account-service -n $NAMESPACE${NC}"
    echo -e "  • All service logs:      ${BLUE}kubectl logs -f -l app=account-service -n $NAMESPACE${NC}"
    echo -e "  • Pod description:       ${BLUE}kubectl describe pod [pod-name] -n $NAMESPACE${NC}"
    echo -e "  • Recent events:         ${BLUE}kubectl get events -n $NAMESPACE --sort-by=.metadata.creationTimestamp${NC}"
    echo ""
    
    echo -e "${GREEN}Updates & Maintenance:${NC}"
    echo -e "  • Rolling update:        ${BLUE}kubectl set image deployment/account-service account-service=new-image:tag -n $NAMESPACE${NC}"
    echo -e "  • Restart deployment:    ${BLUE}kubectl rollout restart deployment/account-service -n $NAMESPACE${NC}"
    echo -e "  • Check rollout status:  ${BLUE}kubectl rollout status deployment/account-service -n $NAMESPACE${NC}"
    echo ""
    
    echo -e "${GREEN}Cleanup:${NC}"
    echo -e "  • Delete specific pod:   ${BLUE}kubectl delete pod [pod-name] -n $NAMESPACE${NC}"
    echo -e "  • Delete deployment:     ${BLUE}kubectl delete deployment [service-name] -n $NAMESPACE${NC}"
    echo -e "  • Delete everything:     ${BLUE}kubectl delete namespace $NAMESPACE${NC}"
    echo -e "  • Stop port forwarding:  ${BLUE}pkill -f 'kubectl.*port-forward'${NC}"
    echo ""
}

show_quick_start() {
    print_section "🚀 Quick Start Commands"
    echo ""
    
    echo -e "${GREEN}1. Access Grafana Dashboards:${NC}"
    echo -e "   ${BLUE}kubectl port-forward svc/grafana 3000:3000 -n $NAMESPACE &${NC}"
    echo -e "   ${BLUE}open http://localhost:3000${NC}  # Login: myuser/mypassword"
    echo ""
    
    echo -e "${GREEN}2. Test APIs:${NC}"
    echo -e "   ${BLUE}kubectl port-forward svc/account-service 8081:8081 -n $NAMESPACE &${NC}"
    echo -e "   ${BLUE}curl http://localhost:8081/actuator/health${NC}"
    echo ""
    
    echo -e "${GREEN}3. Monitor Metrics:${NC}"
    echo -e "   ${BLUE}kubectl port-forward svc/prometheus 9090:9090 -n $NAMESPACE &${NC}"
    echo -e "   ${BLUE}open http://localhost:9090${NC}"
    echo ""
    
    echo -e "${GREEN}4. Generate Load:${NC}"
    echo -e "   ${BLUE}kubectl scale deployment account-service --replicas=3 -n $NAMESPACE${NC}"
    echo -e "   ${BLUE}# Use Postman Runner or k6 for load testing${NC}"
    echo ""
}

main() {
    print_header
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}❌ kubectl is not installed or not in PATH${NC}"
        exit 1
    fi
    
    # Check if cluster is accessible
    if ! kubectl cluster-info &>/dev/null; then
        echo -e "${RED}❌ Cannot connect to Kubernetes cluster${NC}"
        exit 1
    fi
    
    case "${1:-status}" in
        "status"|"")
            check_deployment_status
            show_service_urls
            ;;
        "dashboards"|"grafana")
            show_grafana_dashboards
            ;;
        "test"|"testing")
            show_testing_info
            ;;
        "manage"|"management")
            show_management_commands
            ;;
        "start"|"quickstart")
            show_quick_start
            ;;
        "all")
            check_deployment_status
            show_service_urls
            show_grafana_dashboards
            show_testing_info
            show_management_commands
            show_quick_start
            ;;
        "--help"|"-h"|"help")
            echo "Usage: $0 [COMMAND]"
            echo ""
            echo "Commands:"
            echo "  status      Show deployment status and service URLs (default)"
            echo "  dashboards  Show Grafana dashboard information"
            echo "  test        Show testing and validation commands"
            echo "  manage      Show management and scaling commands"
            echo "  start       Show quick start commands"
            echo "  all         Show all information"
            echo "  help        Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown command: $1${NC}"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}🎉 Your Core Bank System is running on Kubernetes!${NC}"
    echo -e "${BLUE}ℹ️  Use '$0 help' to see all available commands${NC}"
    echo ""
}

main "$@"
