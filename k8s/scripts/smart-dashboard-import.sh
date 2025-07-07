#!/bin/bash

# Smart Grafana Dashboard Import Script
# This script prevents duplicates by checking existing dashboards and deleting them before importing

set -e

NAMESPACE="core-bank"
GRAFANA_PORT="3000"
GRAFANA_USER="myuser"
GRAFANA_PASSWORD="mypassword"

echo "🚀 Smart Grafana Dashboard Import (No Duplicates)"
echo "================================================="

# Check if we're in the correct directory
if [ ! -d "monitoring/grafana/dashboards" ]; then
    if [ -d "../monitoring/grafana/dashboards" ]; then
        cd ..
        echo "📁 Changed to parent directory to find dashboards"
    else
        echo "❌ Cannot find dashboard files. Please run from core-bank directory."
        exit 1
    fi
fi

# Setup port forwarding if needed
echo "📡 Checking Grafana connectivity..."
if ! curl -f -s "http://localhost:$GRAFANA_PORT/api/health" > /dev/null 2>&1; then
    echo "📡 Setting up port forwarding..."
    pkill -f "kubectl.*port-forward.*grafana" 2>/dev/null || true
    kubectl port-forward svc/grafana $GRAFANA_PORT:$GRAFANA_PORT -n $NAMESPACE > /dev/null 2>&1 &
    sleep 5
fi

grafana_url="http://localhost:$GRAFANA_PORT"

# Function to delete dashboard by title
delete_dashboard_by_title() {
    local title="$1"
    echo "  🔍 Checking for existing dashboard: $title"
    
    # Search for dashboard by title
    local search_result=$(curl -s -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
        "$grafana_url/api/search?query=$(echo "$title" | sed 's/ /%20/g')" 2>/dev/null)
    
    # Extract UIDs of dashboards with matching title
    local uids=$(echo "$search_result" | jq -r '.[] | select(.title == "'"$title"'") | .uid' 2>/dev/null)
    
    if [ -n "$uids" ]; then
        echo "$uids" | while read -r uid; do
            if [ -n "$uid" ] && [ "$uid" != "null" ]; then
                echo "  🗑️ Deleting existing dashboard: $uid"
                curl -s -X DELETE -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
                    "$grafana_url/api/dashboards/uid/$uid" > /dev/null 2>&1
            fi
        done
    else
        echo "  ✅ No existing dashboard found with title: $title"
    fi
}

# Import dashboard function
import_dashboard() {
    local dashboard_file="$1"
    local dashboard_name=$(basename "$dashboard_file" .json)
    
    if [ ! -f "$dashboard_file" ]; then
        echo "  ❌ Dashboard file not found: $dashboard_file"
        return 1
    fi
    
    echo "📊 Processing dashboard: $dashboard_name"
    
    # Read dashboard content
    local dashboard_content=$(cat "$dashboard_file")
    
    # Extract dashboard title for duplicate checking
    local dashboard_title
    if echo "$dashboard_content" | jq -e '.dashboard.title' >/dev/null 2>&1; then
        dashboard_title=$(echo "$dashboard_content" | jq -r '.dashboard.title')
    else
        dashboard_title=$(echo "$dashboard_content" | jq -r '.title')
    fi
    
    # Delete any existing dashboard with the same title
    delete_dashboard_by_title "$dashboard_title"
    
    # Prepare import payload
    local import_payload
    if echo "$dashboard_content" | jq -e '.dashboard' >/dev/null 2>&1; then
        # JSON already has dashboard wrapper, just add overwrite flag
        import_payload=$(echo "$dashboard_content" | jq '. + {"overwrite": true}')
    else
        # Wrap the dashboard JSON
        import_payload=$(jq -n --argjson dashboard "$dashboard_content" '{"dashboard": $dashboard, "overwrite": true}')
    fi
    
    # Import dashboard
    echo "  📈 Importing: $dashboard_title"
    local result=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
        -d "$import_payload" \
        "$grafana_url/api/dashboards/db" 2>/dev/null)
    
    if [[ $result == *"success"* ]]; then
        echo "  ✅ Successfully imported: $dashboard_title"
        return 0
    else
        echo "  ❌ Failed to import: $dashboard_title"
        echo "  Response: $result"
        return 1
    fi
}

# Create Prometheus datasource if it doesn't exist
echo "🔗 Ensuring Prometheus datasource exists..."
datasource_check=$(curl -s -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    "$grafana_url/api/datasources/name/Prometheus" 2>/dev/null || echo "NOT_FOUND")

if [[ $datasource_check == *"NOT_FOUND"* ]] || [[ $datasource_check == *"error"* ]]; then
    echo "  📊 Creating Prometheus datasource..."
    curl -s -X POST \
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
        "$grafana_url/api/datasources" > /dev/null
    echo "  ✅ Prometheus datasource created"
else
    echo "  ✅ Prometheus datasource already exists"
fi

# Import dashboards
dashboard_files=(
    "monitoring/grafana/dashboards/core-bank-overview.json"
    "monitoring/grafana/dashboards/service-details.json"
    "monitoring/grafana/dashboards/business-metrics.json"
)

echo ""
echo "📈 Importing dashboards..."
imported_count=0
total_count=${#dashboard_files[@]}

for dashboard_file in "${dashboard_files[@]}"; do
    if import_dashboard "$dashboard_file"; then
        imported_count=$((imported_count + 1))
    fi
    echo ""
done

echo "🎉 Dashboard import completed!"
echo "📊 Successfully imported: $imported_count/$total_count dashboards"
echo ""
echo "🌐 Access Grafana at: $grafana_url"
echo "🔐 Login: $GRAFANA_USER / $GRAFANA_PASSWORD"
echo ""
echo "💡 To stop port forwarding: pkill -f 'kubectl.*port-forward'"
