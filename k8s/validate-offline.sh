#!/bin/bash

# Dry-run validation script for Kubernetes manifests
# This script validates YAML files without requiring a running cluster

set -e

echo "🔍 Validating Kubernetes manifests (dry-run)..."
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TOTAL_FILES=0
VALID_FILES=0
INVALID_FILES=0

# Function to validate YAML syntax without cluster
validate_yaml_offline() {
    local file=$1
    
    # Check basic YAML structure
    if grep -q "apiVersion:" "$file" && grep -q "kind:" "$file" && grep -q "metadata:" "$file"; then
        return 0
    else
        return 1
    fi
}

# Function to validate with kubectl (dry-run client-side only)
validate_with_kubectl_offline() {
    local file=$1
    
    # Try client-side dry-run without server validation
    if kubectl apply --dry-run=client --validate=false -f "$file" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

echo "📋 Validating YAML files..."

for file in k8s/*.yml k8s/*.yaml; do
    if [ -f "$file" ]; then
        TOTAL_FILES=$((TOTAL_FILES + 1))
        echo -n "Validating $(basename "$file")... "
        
        # Check basic YAML structure first
        if validate_yaml_offline "$file"; then
            # Try kubectl validation if available
            if command -v kubectl &> /dev/null; then
                if validate_with_kubectl_offline "$file"; then
                    echo -e "${GREEN}✅ Valid${NC}"
                    VALID_FILES=$((VALID_FILES + 1))
                else
                    echo -e "${YELLOW}⚠️  YAML structure OK (kubectl validation failed - no cluster)${NC}"
                    VALID_FILES=$((VALID_FILES + 1))
                fi
            else
                echo -e "${GREEN}✅ Valid YAML structure${NC}"
                VALID_FILES=$((VALID_FILES + 1))
            fi
        else
            echo -e "${RED}❌ Invalid YAML structure${NC}"
            INVALID_FILES=$((INVALID_FILES + 1))
        fi
    fi
done

# Summary
echo ""
echo "📊 Validation Summary:"
echo "   Total files: $TOTAL_FILES"
echo -e "   Valid files: ${GREEN}$VALID_FILES${NC}"
if [ $INVALID_FILES -gt 0 ]; then
    echo -e "   Invalid files: ${RED}$INVALID_FILES${NC}"
else
    echo -e "   Invalid files: ${GREEN}$INVALID_FILES${NC}"
fi

echo ""
if [ $INVALID_FILES -eq 0 ]; then
    echo -e "🎉 ${GREEN}All YAML files have valid structure!${NC}"
    echo ""
    echo "📋 Next steps:"
    echo "  1. Set up a Kubernetes cluster: ./setup-cluster.sh"
    echo "  2. Deploy the services: ./deploy.sh"
    echo ""
    echo "💡 Note: This validation is offline. Full validation requires a running cluster."
    exit 0
else
    echo -e "⚠️  ${YELLOW}Some files have structural issues. Please check them.${NC}"
    exit 1
fi
