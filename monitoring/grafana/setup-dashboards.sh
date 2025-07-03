#!/bin/bash

# Grafana Dashboard Setup Script for Core Bank System
# This script helps set up Grafana dashboards and data sources

set -e

echo "🚀 Setting up Grafana Dashboard for Core Bank System"

# Check if Grafana is running
check_grafana() {
    echo "📡 Checking Grafana status..."
    if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
        echo "✅ Grafana is running on http://localhost:3000"
    else
        echo "❌ Grafana is not accessible. Please ensure it's running on port 3000"
        exit 1
    fi
}

# Check if Prometheus is running
check_prometheus() {
    echo "📊 Checking Prometheus status..."
    if curl -s http://localhost:9090/api/v1/query?query=up > /dev/null 2>&1; then
        echo "✅ Prometheus is running on http://localhost:9090"
    else
        echo "❌ Prometheus is not accessible. Please ensure it's running on port 9090"
        exit 1
    fi
}

# Import dashboard via Grafana API
import_dashboard() {
    local dashboard_file=$1
    local dashboard_name=$2
    
    echo "📊 Importing dashboard: $dashboard_name"
    
    # Read the dashboard JSON
    dashboard_json=$(cat "$dashboard_file")
    
    # Create the payload for Grafana API
    payload=$(cat <<EOF
{
  "dashboard": $dashboard_json,
  "overwrite": true,
  "inputs": [
    {
      "name": "DS_PROMETHEUS",
      "type": "datasource",
      "pluginId": "prometheus",
      "value": "Prometheus"
    }
  ]
}
EOF
)
    
    # Import dashboard
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -u "myuser:mypassword" \
        -d "$payload" \
        http://localhost:3000/api/dashboards/import)
    
    if echo "$response" | grep -q '"status":"success"'; then
        echo "✅ Successfully imported $dashboard_name"
    else
        echo "❌ Failed to import $dashboard_name"
        echo "Response: $response"
    fi
}

# Create Prometheus data source
create_prometheus_datasource() {
    echo "🔗 Creating Prometheus data source..."
    
    datasource_payload=$(cat <<EOF
{
  "name": "Prometheus",
  "type": "prometheus",
  "url": "http://prometheus:9090",
  "access": "proxy",
  "isDefault": true,
  "jsonData": {
    "timeInterval": "15s"
  }
}
EOF
)
    
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -u "myuser:mypassword" \
        -d "$datasource_payload" \
        http://localhost:3000/api/datasources)
    
    if echo "$response" | grep -q '"message":"Datasource added"'; then
        echo "✅ Successfully created Prometheus data source"
    elif echo "$response" | grep -q '"message":"data source with the same name already exists"'; then
        echo "ℹ️  Prometheus data source already exists"
    else
        echo "❌ Failed to create Prometheus data source"
        echo "Response: $response"
    fi
}

# Main setup function
main() {
    echo "🏦 Core Bank System - Grafana Dashboard Setup"
    echo "=============================================="
    
    # Change to script directory
    cd "$(dirname "$0")"
    
    # Check prerequisites
    check_grafana
    check_prometheus
    
    # Create data source
    create_prometheus_datasource
    
    # Import dashboards
    echo "📊 Importing dashboards..."
    
    if [ -f "dashboards/core-bank-overview.json" ]; then
        import_dashboard "dashboards/core-bank-overview.json" "Core Bank System - Microservices Overview"
    fi
    
    if [ -f "dashboards/service-details.json" ]; then
        import_dashboard "dashboards/service-details.json" "Core Bank System - Service Details"
    fi
    
    if [ -f "dashboards/business-metrics.json" ]; then
        import_dashboard "dashboards/business-metrics.json" "Core Bank System - Business Metrics"
    fi
    
    echo ""
    echo "🎉 Grafana setup completed!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Open Grafana at http://localhost:3000"
    echo "2. Login with username: myuser, password: mypassword"
    echo "3. Navigate to Dashboards to view your imported dashboards"
    echo "4. If dashboards are not visible, see MANUAL_SETUP.md for manual import"
    echo ""
    echo "📊 Available Dashboards:"
    echo "- Core Bank System - Microservices Overview"
    echo "- Core Bank System - Service Details"
    echo "- Core Bank System - Business Metrics"
    echo ""
    echo "🚨 Troubleshooting:"
    echo "- If no data appears, wait 2-3 minutes for metrics to populate"
    echo "- Check Prometheus targets: http://localhost:9090/targets"
    echo "- For manual setup: see MANUAL_SETUP.md"
}

# Run main function
main "$@"
