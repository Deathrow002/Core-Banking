#!/bin/bash

# Core Bank System - Docker Compose Deployment Script
# This script deploys the entire core banking system with monitoring

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.yml"
GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="myuser"
GRAFANA_PASSWORD="mypassword"
PROMETHEUS_URL="http://localhost:9090"

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}🏦 Core Bank System - Docker Deployment${NC}"
    echo -e "${BLUE}================================================${NC}"
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

# Check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed or not in PATH"
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        exit 1
    fi
    
    print_success "Prerequisites check completed"
    echo ""
}

# Clean up existing containers and volumes
cleanup() {
    print_step "Cleaning up existing containers and volumes..."
    
    # Stop and remove containers
    docker-compose down --remove-orphans 2>/dev/null || true
    
    # Remove unused networks
    docker network prune -f 2>/dev/null || true
    
    print_success "Cleanup completed"
    echo ""
}

# Build and start services
deploy_services() {
    print_step "Building and starting services..."
    
    # Build images
    print_info "Building Docker images..."
    docker-compose build --no-cache
    
    # Start infrastructure services first
    print_info "Starting infrastructure services (PostgreSQL, Redis, Kafka)..."
    docker-compose up -d postgres redis kafka
    
    # Wait for infrastructure
    print_info "Waiting for infrastructure services to be ready..."
    sleep 30
    
    # Start monitoring services
    print_info "Starting monitoring services (Prometheus, Grafana)..."
    docker-compose up -d prometheus grafana
    
    # Wait for monitoring
    print_info "Waiting for monitoring services to be ready..."
    sleep 20
    
    # Start discovery service
    print_info "Starting Discovery Service..."
    docker-compose up -d discovery-service
    
    # Wait for discovery service
    print_info "Waiting for Discovery Service to be ready..."
    sleep 30
    
    # Start core services
    print_info "Starting core services..."
    docker-compose up -d authentication-service account-service customer-service transaction-service
    
    print_success "All services deployed"
    echo ""
}

# Check service health
check_service_health() {
    print_step "Checking service health..."
    
    local services=(
        "postgres:5432"
        "redis:6379"
        "kafka:9092"
        "prometheus:9090"
        "grafana:3000"
        "discovery-service:8761"
        "authentication-service:8084"
        "account-service:8081"
        "customer-service:8083"
        "transaction-service:8082"
    )
    
    for service in "${services[@]}"; do
        local name=$(echo $service | cut -d: -f1)
        local port=$(echo $service | cut -d: -f2)
        
        print_info "Checking $name on port $port..."
        
        # Wait up to 60 seconds for service to be ready
        local count=0
        while [ $count -lt 12 ]; do
            if curl -f -s "http://localhost:$port" > /dev/null 2>&1 || \
               nc -z localhost $port 2>/dev/null; then
                print_success "$name is healthy"
                break
            fi
            
            count=$((count + 1))
            if [ $count -eq 12 ]; then
                print_error "$name is not responding on port $port"
            else
                sleep 5
            fi
        done
    done
    
    echo ""
}

# Setup Grafana dashboards
setup_grafana_dashboards() {
    print_step "Setting up Grafana dashboards..."
    
    # Wait for Grafana to be fully ready
    print_info "Waiting for Grafana API to be ready..."
    local count=0
    while [ $count -lt 24 ]; do
        if curl -f -s "$GRAFANA_URL/api/health" > /dev/null 2>&1; then
            print_success "Grafana API is ready"
            break
        fi
        
        count=$((count + 1))
        if [ $count -eq 24 ]; then
            print_error "Grafana API is not responding after 2 minutes"
            return 1
        else
            sleep 5
        fi
    done
    
    # Check if datasource exists
    print_info "Checking Prometheus datasource..."
    local datasource_check=$(curl -s -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
        "$GRAFANA_URL/api/datasources/name/Prometheus" 2>/dev/null || echo "NOT_FOUND")
    
    if [[ $datasource_check == *"NOT_FOUND"* ]] || [[ $datasource_check == *"error"* ]]; then
        print_info "Creating Prometheus datasource..."
        curl -X POST \
            -H "Content-Type: application/json" \
            -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
            -d '{
                "name": "Prometheus",
                "type": "prometheus",
                "url": "http://prometheus:9090",
                "access": "proxy",
                "isDefault": true
            }' \
            "$GRAFANA_URL/api/datasources"
        echo ""
        print_success "Prometheus datasource created"
    else
        print_success "Prometheus datasource already exists"
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
            print_info "Importing dashboard: $dashboard_name..."
            
            local dashboard_json=$(cat "$dashboard_file")
            local import_payload="{\"dashboard\": $dashboard_json, \"overwrite\": true}"
            
            local result=$(curl -s -X POST \
                -H "Content-Type: application/json" \
                -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
                -d "$import_payload" \
                "$GRAFANA_URL/api/dashboards/db")
            
            if [[ $result == *"success"* ]]; then
                print_success "Dashboard $dashboard_name imported successfully"
            else
                print_error "Failed to import dashboard $dashboard_name"
                echo "Response: $result"
            fi
        else
            print_error "Dashboard file not found: $dashboard_file"
        fi
    done
    
    echo ""
}

# Display service URLs and information
display_service_info() {
    print_step "Deployment completed! Service information:"
    echo ""
    
    echo -e "${GREEN}🌐 Service URLs:${NC}"
    echo -e "  • Grafana Dashboard:     ${BLUE}$GRAFANA_URL${NC} (admin: $GRAFANA_USER/$GRAFANA_PASSWORD)"
    echo -e "  • Prometheus:            ${BLUE}$PROMETHEUS_URL${NC}"
    echo -e "  • Discovery Service:     ${BLUE}http://localhost:8761${NC}"
    echo -e "  • Authentication API:    ${BLUE}http://localhost:8084${NC}"
    echo -e "  • Account API:           ${BLUE}http://localhost:8081${NC}"
    echo -e "  • Customer API:          ${BLUE}http://localhost:8083${NC}"
    echo -e "  • Transaction API:       ${BLUE}http://localhost:8082${NC}"
    echo ""
    
    echo -e "${GREEN}📊 Grafana Dashboards:${NC}"
    echo -e "  • Core Bank Overview:    System-wide metrics and health"
    echo -e "  • Service Details:       Individual service performance"
    echo -e "  • Business Metrics:      Banking operations and KPIs"
    echo ""
    
    echo -e "${GREEN}🔧 Useful Commands:${NC}"
    echo -e "  • View logs:             ${BLUE}docker-compose logs -f [service-name]${NC}"
    echo -e "  • Check status:          ${BLUE}docker-compose ps${NC}"
    echo -e "  • Stop services:         ${BLUE}docker-compose down${NC}"
    echo -e "  • Restart service:       ${BLUE}docker-compose restart [service-name]${NC}"
    echo ""
    
    echo -e "${GREEN}🧪 Testing:${NC}"
    echo -e "  • Postman Collections:   ${BLUE}postman/CoreBank-Docker-Compose.postman_collection.json${NC}"
    echo -e "  • Health Checks:         ${BLUE}curl http://localhost:8081/actuator/health${NC}"
    echo ""
}

# Main deployment function
main() {
    print_header
    
    # Parse command line arguments
    local skip_cleanup=false
    local skip_dashboards=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-cleanup)
                skip_cleanup=true
                shift
                ;;
            --skip-dashboards)
                skip_dashboards=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --skip-cleanup      Skip cleanup of existing containers"
                echo "  --skip-dashboards   Skip Grafana dashboard setup"
                echo "  --help, -h          Show this help message"
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
    
    if [ "$skip_cleanup" != true ]; then
        cleanup
    fi
    
    deploy_services
    check_service_health
    
    if [ "$skip_dashboards" != true ]; then
        setup_grafana_dashboards
    fi
    
    display_service_info
    
    print_success "Core Bank System deployment completed successfully!"
}

# Handle script interruption
trap 'echo -e "\n${RED}⚠️  Deployment interrupted${NC}"; exit 1' INT TERM

# Run main function with all arguments
main "$@"
