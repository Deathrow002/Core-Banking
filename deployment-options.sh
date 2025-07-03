#!/bin/bash

# Core Bank System - Deployment Options Summary
# This script shows all available deployment methods

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}🏦 Core Bank System - Deployment Options${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo ""
}

print_section() {
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}$(printf '=%.0s' $(seq 1 ${#1}))${NC}"
}

print_option() {
    echo -e "${GREEN}$1${NC}"
    echo -e "${YELLOW}$2${NC}"
    echo ""
}

print_command() {
    echo -e "   ${BLUE}$1${NC}"
}

main() {
    print_header
    
    print_section "🚀 Quick Deployment Options"
    echo ""
    
    print_option "1. 🎯 One-Command Full Deployment (Recommended)" \
                 "Deploys everything including services, monitoring, and Grafana dashboards"
    print_command "./deploy.sh"
    
    print_option "2. ⚡ Fast Deployment (Skip Cleanup)" \
                 "Faster deployment for development, skips container cleanup"
    print_command "./deploy.sh --skip-cleanup"
    
    print_option "3. 🔧 Services Only (No Dashboards)" \
                 "Deploy services and monitoring, but skip Grafana dashboard setup"
    print_command "./deploy.sh --skip-dashboards"
    
    print_section "📊 Grafana Dashboard Setup"
    echo ""
    
    print_option "4. 📈 Dashboard Setup Only" \
                 "Setup Grafana dashboards on existing deployment"
    print_command "./setup-grafana.sh"
    
    print_option "5. 🔐 Custom Grafana Credentials" \
                 "Setup dashboards with custom username/password"
    print_command "./setup-grafana.sh --username admin --password secret"
    
    print_section "🐳 Manual Docker Compose"
    echo ""
    
    print_option "6. 📋 Manual Step-by-Step" \
                 "Manual deployment with full control over each step"
    print_command "docker-compose up -d postgres redis kafka    # Infrastructure"
    print_command "docker-compose up -d prometheus grafana       # Monitoring"
    print_command "docker-compose up -d discovery-service        # Service Discovery"
    print_command "docker-compose up -d authentication-service account-service customer-service transaction-service"
    print_command "./setup-grafana.sh                            # Dashboard setup"
    
    print_option "7. 🚪 Basic Docker Compose" \
                 "Simple Docker Compose deployment without automation"
    print_command "docker-compose up -d"
    
    print_section "☸️ Kubernetes Deployment"
    echo ""
    
    print_option "8. 🌐 Kubernetes Production" \
                 "Production deployment with Kubernetes (requires kubectl)"
    print_command "./k8s/deploy.sh"
    
    print_section "📚 Documentation & Help"
    echo ""
    
    print_option "📖 Detailed Deployment Guide" \
                 "Step-by-step instructions with troubleshooting"
    print_command "cat DEPLOYMENT_GUIDE.md"
    
    print_option "❓ Script Help" \
                 "Get help for specific deployment scripts"
    print_command "./deploy.sh --help"
    print_command "./setup-grafana.sh --help"
    print_command "./k8s/deploy.sh --help"
    
    print_section "🌐 Service URLs (After Deployment)"
    echo ""
    
    echo -e "${GREEN}Main Services:${NC}"
    echo -e "  • ${BLUE}Grafana Dashboard:${NC}     http://localhost:3000 (myuser/mypassword)"
    echo -e "  • ${BLUE}Prometheus:${NC}            http://localhost:9090"
    echo -e "  • ${BLUE}Discovery Service:${NC}     http://localhost:8761"
    echo ""
    
    echo -e "${GREEN}API Endpoints:${NC}"
    echo -e "  • ${BLUE}Authentication:${NC}        http://localhost:8084"
    echo -e "  • ${BLUE}Account Service:${NC}       http://localhost:8081"
    echo -e "  • ${BLUE}Customer Service:${NC}      http://localhost:8083"
    echo -e "  • ${BLUE}Transaction Service:${NC}   http://localhost:8082"
    echo ""
    
    print_section "🧪 Testing & Verification"
    echo ""
    
    print_option "✅ Health Checks" \
                 "Verify all services are running correctly"
    print_command "docker-compose ps"
    print_command "curl http://localhost:8081/actuator/health"
    
    print_option "📮 API Testing" \
                 "Test APIs using Postman collection"
    print_command "# Import: postman/CoreBank-Docker-Compose.postman_collection.json"
    
    print_section "🔧 Management Commands"
    echo ""
    
    print_option "📊 View Logs" \
                 "Monitor service logs"
    print_command "docker-compose logs -f [service-name]"
    
    print_option "🔄 Restart Services" \
                 "Restart specific or all services"
    print_command "docker-compose restart [service-name]"
    
    print_option "🛑 Stop Services" \
                 "Stop all services"
    print_command "docker-compose down"
    
    echo ""
    echo -e "${GREEN}🎉 Ready to deploy? Choose an option above and get started!${NC}"
    echo ""
}

main "$@"
