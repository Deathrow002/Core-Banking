#!/bin/bash

# Kubernetes Troubleshooting Script for Core Bank System
# This script helps debug deployment issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

NAMESPACE="core-bank"

print_header() {
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}🔧 Core Bank System - Kubernetes Troubleshooting${NC}"
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

troubleshoot_service() {
    local service_name=$1
    
    print_step "Troubleshooting $service_name..."
    
    # Check if pods exist
    local pods=$(kubectl get pods -l app=$service_name -n $NAMESPACE --no-headers 2>/dev/null | wc -l)
    if [ $pods -eq 0 ]; then
        print_error "No pods found for $service_name"
        return 1
    fi
    
    # Get pod status
    echo -e "${BLUE}Pod Status:${NC}"
    kubectl get pods -l app=$service_name -n $NAMESPACE
    echo ""
    
    # Get pod details
    local pod_name=$(kubectl get pods -l app=$service_name -n $NAMESPACE -o jsonpath='{.items[0].metadata.name}')
    
    echo -e "${BLUE}Pod Description (last 20 lines):${NC}"
    kubectl describe pod $pod_name -n $NAMESPACE | tail -20
    echo ""
    
    # Get recent events
    echo -e "${BLUE}Recent Events:${NC}"
    kubectl get events -n $NAMESPACE --field-selector involvedObject.name=$pod_name --sort-by=.metadata.creationTimestamp | tail -10
    echo ""
    
    # Get logs
    echo -e "${BLUE}Pod Logs (last 30 lines):${NC}"
    kubectl logs $pod_name -n $NAMESPACE --tail=30 2>/dev/null || echo "No logs available"
    echo ""
    
    # Check readiness/liveness probes
    echo -e "${BLUE}Health Check Status:${NC}"
    kubectl get pod $pod_name -n $NAMESPACE -o jsonpath='{.status.conditions}' | jq -r '.[] | select(.type=="Ready") | "Ready: \(.status) (\(.reason))"' 2>/dev/null || echo "Ready status: Unknown"
    echo ""
}

fix_common_issues() {
    print_step "Applying common fixes..."
    
    print_info "Checking resource constraints..."
    
    # Check if any pods are pending due to resource constraints
    local pending_pods=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase=Pending --no-headers 2>/dev/null)
    
    if [ -n "$pending_pods" ]; then
        print_info "Found pending pods, checking resource constraints..."
        kubectl describe pods -n $NAMESPACE --field-selector=status.phase=Pending | grep -A 5 "Events:"
    fi
    
    # Restart any crash-looping pods
    local crash_pods=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase=Running --no-headers -o custom-columns=":metadata.name,:status.containerStatuses[0].restartCount" | awk '$2 > 3 {print $1}')
    
    if [ -n "$crash_pods" ]; then
        print_info "Restarting crash-looping pods..."
        echo "$crash_pods" | while read -r pod; do
            kubectl delete pod "$pod" -n $NAMESPACE
        done
    fi
    
    print_success "Common fixes applied"
}

restart_failed_services() {
    print_step "Restarting failed services..."
    
    # Get failed pods
    local failed_pods=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running --no-headers -o custom-columns=":metadata.name" 2>/dev/null)
    
    if [ -n "$failed_pods" ]; then
        echo -e "${BLUE}Failed pods found:${NC}"
        echo "$failed_pods"
        echo ""
        
        # Delete failed pods to trigger restart
        echo "$failed_pods" | while read pod; do
            if [ -n "$pod" ]; then
                print_info "Restarting pod: $pod"
                kubectl delete pod $pod -n $NAMESPACE
            fi
        done
        
        sleep 10
        print_success "Failed pods restarted"
    else
        print_success "No failed pods found"
    fi
}

check_cluster_resources() {
    print_step "Checking cluster resources..."
    
    echo -e "${BLUE}Node Status:${NC}"
    kubectl get nodes
    echo ""
    
    echo -e "${BLUE}Node Resources:${NC}"
    kubectl top nodes 2>/dev/null || echo "Metrics server not available"
    echo ""
    
    echo -e "${BLUE}Namespace Resource Usage:${NC}"
    kubectl top pods -n $NAMESPACE 2>/dev/null || echo "Metrics server not available"
    echo ""
}

main() {
    print_header
    
    if [ $# -eq 0 ]; then
        echo "Usage: $0 [OPTIONS] [SERVICE_NAME]"
        echo ""
        echo "Options:"
        echo "  --fix-common       Apply common fixes"
        echo "  --restart-failed   Restart failed services"
        echo "  --check-resources  Check cluster resources"
        echo "  --all             Run all troubleshooting steps"
        echo ""
        echo "Service Names:"
        echo "  kafka, postgres, redis, prometheus, grafana"
        echo "  discovery-service, authentication-service, account-service"
        echo "  customer-service, transaction-service"
        echo ""
        echo "Examples:"
        echo "  $0 kafka                  # Troubleshoot Kafka"
        echo "  $0 --fix-common           # Apply common fixes"
        echo "  $0 --all                  # Full troubleshooting"
        echo ""
        exit 1
    fi
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --fix-common)
                fix_common_issues
                shift
                ;;
            --restart-failed)
                restart_failed_services
                shift
                ;;
            --check-resources)
                check_cluster_resources
                shift
                ;;
            --all)
                check_cluster_resources
                fix_common_issues
                restart_failed_services
                
                # Troubleshoot all services
                local services=("kafka" "postgres" "redis" "prometheus" "grafana")
                for service in "${services[@]}"; do
                    troubleshoot_service "$service"
                done
                shift
                ;;
            *)
                # Assume it's a service name
                troubleshoot_service "$1"
                shift
                ;;
        esac
    done
    
    print_success "Troubleshooting completed!"
    echo ""
    print_info "Next steps:"
    echo "  1. Check if services are now ready: kubectl get pods -n $NAMESPACE"
    echo "  2. Continue deployment: ./deploy-with-grafana.sh --skip-cleanup"
    echo "  3. View service logs: kubectl logs -f deployment/[service-name] -n $NAMESPACE"
}

main "$@"
