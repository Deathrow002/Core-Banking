#!/bin/bash

# Kubernetes Grafana Dashboard Setup Script
# Run this script to setup dashboards on an existing K8s deployment

set -e

NAMESPACE="core-bank"
GRAFANA_PORT="3000"
GRAFANA_USER="myuser"
GRAFANA_PASSWORD="mypassword"

echo "🚀 Setting up Grafana dashboards for Kubernetes deployment..."

# Setup port forwarding
echo "📡 Setting up port forwarding..."
pkill -f "kubectl.*port-forward.*grafana" 2>/dev/null || true
kubectl port-forward svc/grafana $GRAFANA_PORT:$GRAFANA_PORT -n $NAMESPACE > /dev/null 2>&1 &
sleep 5

# Setup dashboards
echo "📊 Configuring Grafana..."
GRAFANA_URL="http://localhost:$GRAFANA_PORT"

# Create Prometheus datasource
curl -s -X POST \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    -d '{
        "name": "Prometheus",
        "type": "prometheus",
        "url": "http://prometheus:9090",
        "access": "proxy",
        "isDefault": true
    }' \
    "$GRAFANA_URL/api/datasources" > /dev/null

# Import dashboards
dashboard_files=(
    "monitoring/grafana/dashboards/core-bank-overview.json"
    "monitoring/grafana/dashboards/service-details.json"
    "monitoring/grafana/dashboards/business-metrics.json"
)

for dashboard_file in "\${dashboard_files[@]}"; do
    if [ -f "\$dashboard_file" ]; then
        dashboard_name=\$(basename "\$dashboard_file" .json)
        echo "📈 Importing: \$dashboard_name..."
        
        # Read the dashboard JSON
        dashboard_content=\$(cat "\$dashboard_file")
        
        # Check if the JSON already has a dashboard wrapper
        if echo "\$dashboard_content" | jq -e '.dashboard' >/dev/null 2>&1; then
            # JSON already has dashboard wrapper, just add overwrite flag
            import_payload=\$(echo "\$dashboard_content" | jq '. + {"overwrite": true}')
        else
            # Wrap the dashboard JSON
            import_payload="{\\"dashboard\\": \$dashboard_content, \\"overwrite\\": true}"
        fi
        
        result=\$(curl -s -X POST \\
            -H "Content-Type: application/json" \\
            -u "\$GRAFANA_USER:\$GRAFANA_PASSWORD" \\
            -d "\$import_payload" \\
            "\$GRAFANA_URL/api/dashboards/db" 2>/dev/null)
        
        if [[ \$result == *"success"* ]]; then
            echo "✅ \$dashboard_name imported successfully"
        else
            echo "❌ \$dashboard_name import failed: \$result"
        fi
    else
        echo "❌ Dashboard file not found: \$dashboard_file"
    fi
done

echo "✅ Grafana dashboard setup completed!"
echo "🌐 Access Grafana at: $GRAFANA_URL"
echo "🔐 Login: $GRAFANA_USER / $GRAFANA_PASSWORD"
