#!/bin/bash

# Kubernetes cleanup script for Core Bank services

echo "🧹 Cleaning up Core Bank services from Kubernetes..."
echo "================================================="

# Function to delete resources with error handling
delete_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=${3:-core-bank}
    
    if kubectl get $resource_type $resource_name -n $namespace >/dev/null 2>&1; then
        echo "🗑️  Deleting $resource_type/$resource_name..."
        kubectl delete $resource_type $resource_name -n $namespace
    else
        echo "ℹ️   $resource_type/$resource_name not found, skipping..."
    fi
}

# Delete application services first
echo "🏦 Deleting application services..."
delete_resource deployment authentication-service
delete_resource service authentication-service
delete_resource deployment transaction-service
delete_resource service transaction-service
delete_resource deployment customer-service
delete_resource service customer-service
delete_resource deployment account-service
delete_resource service account-service

# Delete infrastructure services
echo "🏗️  Deleting infrastructure services..."
delete_resource deployment kafka
delete_resource service kafka
delete_resource pvc kafka-pvc
delete_resource deployment discovery-service
delete_resource service discovery-service

# Delete monitoring services
echo "📊 Deleting monitoring services..."
delete_resource deployment grafana
delete_resource service grafana
delete_resource pvc grafana-pvc
delete_resource deployment prometheus
delete_resource service prometheus

# Delete data services
echo "🗃️  Deleting data services..."
delete_resource deployment redis
delete_resource service redis
delete_resource pvc redis-pvc
delete_resource deployment postgres
delete_resource service postgres
delete_resource pvc postgres-pvc

# Delete namespace (this will clean up any remaining resources)
echo "📦 Deleting namespace..."
if kubectl get namespace core-bank >/dev/null 2>&1; then
    echo "🗑️  Deleting namespace core-bank..."
    kubectl delete namespace core-bank
else
    echo "ℹ️   Namespace core-bank not found, skipping..."
fi

echo ""
echo "✅ Cleanup completed!"
echo ""
echo "🔍 Remaining resources (should be empty):"
kubectl get all -n core-bank 2>/dev/null || echo "   (namespace not found - cleanup successful)"

echo ""
echo "💡 To verify complete cleanup, you can also run:"
echo "   kubectl get pv | grep core-bank"
echo "   kubectl get pvc --all-namespaces | grep core-bank"
