#!/bin/bash

# Grafana Dashboard Setup Script
# This script sets up Grafana dashboards for the Core Bank System

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="myuser"
GRAFANA_PASSWORD="mypassword"

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}📊 Grafana Dashboard Setup${NC}"
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

# Check if Grafana is running
check_grafana() {
    print_step "Checking Grafana connection..."
    
    local count=0
    while [ $count -lt 12 ]; do
        if curl -f -s "$GRAFANA_URL/api/health" > /dev/null 2>&1; then
            print_success "Grafana is running and accessible"
            return 0
        fi
        
        count=$((count + 1))
        if [ $count -eq 12 ]; then
            print_error "Grafana is not accessible at $GRAFANA_URL"
            echo ""
            echo "Please ensure:"
            echo "  1. Grafana is running: docker-compose ps grafana"
            echo "  2. Port 3000 is accessible: curl $GRAFANA_URL"
            echo "  3. If using different credentials, update this script"
            echo ""
            exit 1
        else
            print_info "Waiting for Grafana to start... (attempt $count/12)"
            sleep 5
        fi
    done
}

# Create or verify Prometheus datasource
setup_datasource() {
    print_step "Setting up Prometheus datasource..."
    
    # Check if datasource exists
    local datasource_check=$(curl -s -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
        "$GRAFANA_URL/api/datasources/name/Prometheus" 2>/dev/null || echo "NOT_FOUND")
    
    if [[ $datasource_check == *"NOT_FOUND"* ]] || [[ $datasource_check == *"error"* ]]; then
        print_info "Creating Prometheus datasource..."
        
        local response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
            -d '{
                "name": "Prometheus",
                "type": "prometheus",
                "url": "http://prometheus:9090",
                "access": "proxy",
                "isDefault": true,
                "jsonData": {
                    "timeInterval": "15s",
                    "queryTimeout": "60s",
                    "httpMethod": "POST"
                }
            }' \
            "$GRAFANA_URL/api/datasources")
        
        if [[ $response == *"success"* ]] || [[ $response == *"Datasource added"* ]]; then
            print_success "Prometheus datasource created successfully"
        else
            print_error "Failed to create Prometheus datasource"
            echo "Response: $response"
            return 1
        fi
    else
        print_success "Prometheus datasource already exists"
    fi
    
    # Test datasource connection
    print_info "Testing Prometheus connection..."
    local test_response=$(curl -s -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
        "$GRAFANA_URL/api/datasources/proxy/1/api/v1/query?query=up" 2>/dev/null)
    
    if [[ $test_response == *"success"* ]]; then
        print_success "Prometheus datasource is working correctly"
    else
        print_error "Prometheus datasource test failed"
        echo "Make sure Prometheus is running: docker-compose ps prometheus"
    fi
    
    echo ""
}

# Import dashboard from JSON file
import_dashboard() {
    local dashboard_file=$1
    local dashboard_name=$(basename "$dashboard_file" .json)
    
    if [ ! -f "$dashboard_file" ]; then
        print_error "Dashboard file not found: $dashboard_file"
        return 1
    fi
    
    print_info "Importing dashboard: $dashboard_name..."
    
    # Read dashboard JSON
    local dashboard_content=$(cat "$dashboard_file")
    
    # Check if the JSON already has a dashboard wrapper
    if echo "$dashboard_content" | jq -e '.dashboard' >/dev/null 2>&1; then
        # JSON already has dashboard wrapper, just add overwrite flag
        local import_payload=$(echo "$dashboard_content" | jq '. + {"overwrite": true}')
    else
        # Create import payload with dashboard wrapper
        local import_payload="{\"dashboard\": $dashboard_content, \"overwrite\": true, \"inputs\": []}"
    fi
    
    # Import dashboard
    local result=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
        -d "$import_payload" \
        "$GRAFANA_URL/api/dashboards/db")
    
    if [[ $result == *"success"* ]]; then
        print_success "Dashboard '$dashboard_name' imported successfully"
        
        # Extract dashboard URL from response
        local dashboard_uid=$(echo "$result" | grep -o '"uid":"[^"]*"' | cut -d'"' -f4)
        if [ -n "$dashboard_uid" ]; then
            print_info "Dashboard URL: $GRAFANA_URL/d/$dashboard_uid/$dashboard_name"
        fi
    else
        print_error "Failed to import dashboard '$dashboard_name'"
        echo "Response: $result"
        return 1
    fi
}

# Setup all dashboards
setup_dashboards() {
    print_step "Importing Grafana dashboards..."
    
    local dashboard_files=(
        "../../monitoring/grafana/dashboards/core-bank-overview.json"
        "../../monitoring/grafana/dashboards/service-details.json"
        "../../monitoring/grafana/dashboards/business-metrics.json"
    )
    
    local imported_count=0
    local total_count=${#dashboard_files[@]}
    
    for dashboard_file in "${dashboard_files[@]}"; do
        if import_dashboard "$dashboard_file"; then
            imported_count=$((imported_count + 1))
        fi
    done
    
    echo ""
    print_success "Dashboard import completed: $imported_count/$total_count dashboards imported"
    echo ""
}

# Create folder for dashboards (optional)
create_folder() {
    print_step "Creating dashboard folder..."
    
    local folder_response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
        -d '{
            "title": "Core Bank System",
            "uid": "core-bank"
        }' \
        "$GRAFANA_URL/api/folders")
    
    if [[ $folder_response == *"success"* ]] || [[ $folder_response == *"title"* ]]; then
        print_success "Dashboard folder created"
    elif [[ $folder_response == *"already exists"* ]]; then
        print_success "Dashboard folder already exists"
    else
        print_info "Folder creation skipped (dashboards will be in General folder)"
    fi
}

# Display dashboard information
display_dashboard_info() {
    print_step "Dashboard setup completed!"
    echo ""
    
    echo -e "${GREEN}📊 Available Dashboards:${NC}"
    echo ""
    
    echo -e "${BLUE}1. Core Bank Overview${NC}"
    echo -e "   📈 System-wide metrics and health monitoring"
    echo -e "   🔗 URL: $GRAFANA_URL/dashboards"
    echo -e "   📊 Metrics: CPU, Memory, Response Times, Error Rates"
    echo ""
    
    echo -e "${BLUE}2. Service Details${NC}"
    echo -e "   🔍 Individual service performance metrics"
    echo -e "   📊 Metrics: JVM stats, Thread pools, Database connections"
    echo ""
    
    echo -e "${BLUE}3. Business Metrics${NC}"
    echo -e "   💰 Banking operations and business KPIs"
    echo -e "   📊 Metrics: Transaction counts, Account operations, Customer activity"
    echo ""
    
    echo -e "${GREEN}🔧 Next Steps:${NC}"
    echo -e "  1. Open Grafana: ${BLUE}$GRAFANA_URL${NC}"
    echo -e "  2. Login with: ${BLUE}$GRAFANA_USER / $GRAFANA_PASSWORD${NC}"
    echo -e "  3. Navigate to Dashboards to view your data"
    echo -e "  4. Generate some traffic to see metrics"
    echo ""
    
    echo -e "${GREEN}🧪 Generate Test Data:${NC}"
    echo -e "  • Use Postman collection: ${BLUE}../../postman/CoreBank-Docker-Compose.postman_collection.json${NC}"
    echo -e "  • Or run manual API calls: ${BLUE}curl http://localhost:8081/actuator/health${NC}"
    echo ""
}

# Main function
main() {
    print_header
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --grafana-url)
                GRAFANA_URL="$2"
                shift 2
                ;;
            --username)
                GRAFANA_USER="$2"
                shift 2
                ;;
            --password)
                GRAFANA_PASSWORD="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --grafana-url URL    Grafana URL (default: http://localhost:3000)"
                echo "  --username USER      Grafana username (default: myuser)"
                echo "  --password PASS      Grafana password (default: mypassword)"
                echo "  --help, -h           Show this help message"
                echo ""
                echo "Example:"
                echo "  $0 --grafana-url http://grafana.example.com --username admin --password secret"
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
    
    # Execute setup steps
    check_grafana
    setup_datasource
    create_folder
    setup_dashboards
    display_dashboard_info
    
    print_success "Grafana dashboard setup completed successfully!"
}

# Handle script interruption
trap 'echo -e "\n${RED}⚠️  Setup interrupted${NC}"; exit 1' INT TERM

# Run main function with all arguments
main "$@"
