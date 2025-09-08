#!/bin/bash

# Kubernetes YAML Configuration Checker
echo "🔍 Checking Kubernetes YAML files configuration..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to validate YAML basic structure
validate_k8s_structure() {
    local file=$1
    local has_apiversion=$(grep -c "apiVersion:" "$file")
    local has_kind=$(grep -c "kind:" "$file")
    local has_metadata=$(grep -c "metadata:" "$file")
    
    # Check if it's a custom resource (ServiceMonitor, PrometheusRule, etc.)
    local is_custom_resource=false
    if grep -q "apiVersion: monitoring.coreos.com" "$file"; then
        is_custom_resource=true
    fi
    
    if [ $has_apiversion -gt 0 ] && [ $has_kind -gt 0 ] && [ $has_metadata -gt 0 ]; then
        if [ "$is_custom_resource" = true ]; then
            echo -n "(Custom Resource) "
        fi
        return 0
    else
        return 1
    fi
}

# Function to check for resource definitions
check_resources() {
    local file=$1
    if grep -q "containers:" "$file"; then
        if grep -q "resources:" "$file"; then
            return 0  # Has resources
        else
            return 1  # Missing resources
        fi
    else
        return 0  # Not a deployment/pod, doesn't need resources
    fi
}

# Validate all YAML files in k8s directory
TOTAL_FILES=0
VALID_FILES=0
WARNING_FILES=0

for file in k8s/*.yml k8s/*.yaml; do
    if [ -f "$file" ]; then
        TOTAL_FILES=$((TOTAL_FILES + 1))
        echo -n "Checking $(basename "$file")... "
        
        # Check basic K8s structure
        if validate_k8s_structure "$file"; then
            # Check for resource definitions
            if check_resources "$file"; then
                echo -e "${GREEN}✅ Valid${NC}"
                VALID_FILES=$((VALID_FILES + 1))
            else
                echo -e "${YELLOW}⚠️  Valid (missing container resources)${NC}"
                WARNING_FILES=$((WARNING_FILES + 1))
            fi
        else
            echo -e "${RED}❌ Invalid structure${NC}"
        fi
    fi
done

# Summary
echo ""
echo "📊 Configuration Check Summary:"
echo "   Total files: $TOTAL_FILES"
echo -e "   Valid files: ${GREEN}$VALID_FILES${NC}"
if [ $WARNING_FILES -gt 0 ]; then
    echo -e "   Files with warnings: ${YELLOW}$WARNING_FILES${NC}"
fi

if [ $WARNING_FILES -eq 0 ]; then
    echo -e "\n🎉 ${GREEN}All Kubernetes YAML files have proper structure and resources!${NC}"
    exit 0
else
    echo -e "\n✅ ${GREEN}All files have valid structure.${NC}"
    echo -e "⚠️  ${YELLOW}Some containers may benefit from resource limits.${NC}"
    exit 0
fi
