#!/bin/bash

# Core Bank System - All Deployment Options
# This script shows all available deployment methods for Docker and Kubernetes

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}🏦 Core Bank System - Complete Deployment Guide${NC}"
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
    
    print_section "🐳 Docker Compose Deployment"
    echo ""
    
    print_option "1. 🎯 Complete Docker Deployment (Recommended for Development)" \
                 "One-command deployment with all services and Grafana dashboards"
    print_command "./deploy.sh"
    
    print_option "2. ⚡ Fast Docker Deployment" \
                 "Skip cleanup for faster development cycles"
    print_command "./deploy.sh --skip-cleanup"
    
    print_option "3. 🔧 Docker Services Only" \
                 "Deploy services without Grafana dashboard setup"
    print_command "./deploy.sh --skip-dashboards"
    
    print_option "4. 📊 Docker Dashboard Setup Only" \
                 "Setup Grafana dashboards on existing Docker deployment"
    print_command "./setup-grafana.sh"
    
    print_option "5. 📋 Manual Docker Compose" \
                 "Traditional Docker Compose deployment"
    print_command "docker-compose up -d"
    
    print_section "☸️ Kubernetes Deployment"
    echo ""
    
    print_option "6. 🚀 Complete K8s Deployment (Recommended for Production)" \
                 "Full Kubernetes deployment with monitoring and dashboards"
    print_command "cd k8s && ./deploy-with-grafana.sh"
    
    print_option "7. ⚙️ K8s with Custom Options" \
                 "Kubernetes deployment with specific configurations"
    print_command "cd k8s && ./deploy-with-grafana.sh --port-forward"
    print_command "cd k8s && ./deploy-with-grafana.sh --namespace my-bank"
    print_command "cd k8s && ./deploy-with-grafana.sh --skip-dashboards"
    
    print_option "8. 📊 K8s Dashboard Setup Only" \
                 "Setup Grafana dashboards on existing K8s deployment"
    print_command "cd k8s && ./setup-k8s-grafana-dashboards.sh"
    
    print_option "9. 🔧 Standard K8s Deployment" \
                 "Use existing K8s script (without Grafana automation)"
    print_command "cd k8s && ./deploy.sh"
    
    print_option "10. 📋 Manual K8s Deployment" \
                  "Step-by-step Kubernetes deployment"
    print_command "cd k8s && kubectl apply -f namespace.yml"
    print_command "kubectl apply -f postgres.yml redis.yml kafka.yml"
    print_command "kubectl apply -f prometheus.yml grafana.yml"
    print_command "kubectl apply -f *-service.yml"
    
    print_section "🎭 Environment-Specific Recommendations"
    echo ""
    
    echo -e "${MAGENTA}🖥️  Local Development:${NC}"
    echo -e "   • Use Docker Compose: ${BLUE}./deploy.sh${NC}"
    echo -e "   • Faster iteration: ${BLUE}./deploy.sh --skip-cleanup${NC}"
    echo -e "   • Resource requirements: 8GB RAM, Docker Desktop"
    echo ""
    
    echo -e "${MAGENTA}🧪 Testing Environment:${NC}"
    echo -e "   • Use Kubernetes: ${BLUE}cd k8s && ./deploy-with-grafana.sh${NC}"
    echo -e "   • Easy scaling: ${BLUE}kubectl scale deployment account-service --replicas=3${NC}"
    echo -e "   • Resource requirements: minikube, kind, or cloud cluster"
    echo ""
    
    echo -e "${MAGENTA}🏭 Production Environment:${NC}"
    echo -e "   • Use Kubernetes with persistence: ${BLUE}cd k8s && ./deploy-with-grafana.sh${NC}"
    echo -e "   • Setup ingress, TLS, and persistent storage"
    echo -e "   • Configure monitoring alerts and backup strategies"
    echo ""
    
    print_section "🌐 Service Access URLs"
    echo ""
    
    echo -e "${GREEN}Docker Compose URLs:${NC}"
    echo -e "  • Grafana:      ${BLUE}http://localhost:3000${NC} (myuser/mypassword)"
    echo -e "  • Prometheus:   ${BLUE}http://localhost:9090${NC}"
    echo -e "  • APIs:         ${BLUE}http://localhost:8081-8084${NC}"
    echo ""
    
    echo -e "${GREEN}Kubernetes URLs (with port-forward):${NC}"
    echo -e "  • Grafana:      ${BLUE}http://localhost:3000${NC} (myuser/mypassword)"
    echo -e "  • Prometheus:   ${BLUE}http://localhost:9090${NC}"
    echo -e "  • Port forward: ${BLUE}kubectl port-forward svc/grafana 3000:3000 -n core-bank${NC}"
    echo ""
    
    print_section "📊 Grafana Dashboards"
    echo ""
    
    echo -e "${GREEN}Available Dashboards:${NC}"
    echo -e "  📈 ${BLUE}Core Bank Overview${NC}   - System health, performance, and availability"
    echo -e "  🔍 ${BLUE}Service Details${NC}      - Individual microservice deep-dive metrics"
    echo -e "  💰 ${BLUE}Business Metrics${NC}     - Banking operations and business KPIs"
    echo ""
    
    print_section "🧪 Testing & Validation"
    echo ""
    
    print_option "Health Checks" \
                 "Verify all services are running correctly"
    print_command "# Docker: docker-compose ps"
    print_command "# K8s: kubectl get pods -n core-bank"
    print_command "# API: curl http://localhost:8081/actuator/health"
    
    print_option "API Testing" \
                 "Test banking APIs using Postman collections"
    print_command "# Docker: postman/CoreBank-Docker-Compose.postman_collection.json"
    print_command "# K8s: postman/CoreBank-Kubernetes.postman_collection.json"
    
    print_option "Load Testing" \
                 "Generate traffic to see metrics in action"
    print_command "# Scale services: kubectl scale deployment account-service --replicas=3"
    print_command "# Use Postman Runner for automated API calls"
    
    print_section "🔧 Management Commands"
    echo ""
    
    echo -e "${GREEN}Docker Compose:${NC}"
    echo -e "  • View logs:    ${BLUE}docker-compose logs -f [service]${NC}"
    echo -e "  • Restart:      ${BLUE}docker-compose restart [service]${NC}"
    echo -e "  • Stop all:     ${BLUE}docker-compose down${NC}"
    echo -e "  • Scale:        ${BLUE}docker-compose up -d --scale account-service=3${NC}"
    echo ""
    
    echo -e "${GREEN}Kubernetes:${NC}"
    echo -e "  • View logs:    ${BLUE}kubectl logs -f deployment/[service] -n core-bank${NC}"
    echo -e "  • Scale:        ${BLUE}kubectl scale deployment [service] --replicas=3 -n core-bank${NC}"
    echo -e "  • Restart:      ${BLUE}kubectl rollout restart deployment/[service] -n core-bank${NC}"
    echo -e "  • Delete all:   ${BLUE}kubectl delete namespace core-bank${NC}"
    echo ""
    
    print_section "📚 Documentation"
    echo ""
    
    echo -e "${GREEN}Deployment Guides:${NC}"
    echo -e "  • Docker Guide:      ${BLUE}DEPLOYMENT_GUIDE.md${NC}"
    echo -e "  • Kubernetes Guide:  ${BLUE}k8s/K8S_DEPLOYMENT_GUIDE.md${NC}"
    echo -e "  • Monitoring Setup:  ${BLUE}monitoring/QUICK_START.md${NC}"
    echo -e "  • Troubleshooting:   ${BLUE}monitoring/SOLUTION.md${NC}"
    echo ""
    
    print_option "Get Help" \
                 "Show help for specific deployment scripts"
    print_command "./deploy.sh --help"
    print_command "./setup-grafana.sh --help"
    print_command "cd k8s && ./deploy-with-grafana.sh --help"
    print_command "cd k8s && ./deploy.sh --help"
    
    print_section "🚀 Quick Start Commands"
    echo ""
    
    echo -e "${YELLOW}Choose your deployment method:${NC}"
    echo ""
    echo -e "${GREEN}For Local Development (Docker):${NC}"
    echo -e "   ${BLUE}./deploy.sh${NC}"
    echo ""
    echo -e "${GREEN}For Production (Kubernetes):${NC}"
    echo -e "   ${BLUE}cd k8s && ./deploy-with-grafana.sh${NC}"
    echo ""
    echo -e "${GREEN}Dashboard Only Setup:${NC}"
    echo -e "   ${BLUE}./setup-grafana.sh                    # Docker${NC}"
    echo -e "   ${BLUE}cd k8s && ./setup-k8s-grafana-dashboards.sh  # Kubernetes${NC}"
    echo ""
    
    echo -e "${GREEN}🎉 Ready to deploy your Core Bank System! Choose an option above and get started! 🚀${NC}"
    echo ""
}

main "$@"
