#!/bin/bash

# Kubernetes Cluster Setup Script
# This script helps set up a local Kubernetes cluster for Core Bank deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🚀 Kubernetes Cluster Setup for Core Bank"
echo "=========================================="

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check cluster status
check_cluster() {
    echo "🔍 Checking current cluster status..."
    
    if kubectl cluster-info &>/dev/null; then
        echo -e "${GREEN}✅ Kubernetes cluster is accessible${NC}"
        echo "Current context: $(kubectl config current-context)"
        echo "Cluster info:"
        kubectl cluster-info
        return 0
    else
        echo -e "${RED}❌ No accessible Kubernetes cluster found${NC}"
        return 1
    fi
}

# Function to setup Docker Desktop Kubernetes
setup_docker_desktop() {
    echo "🐳 Setting up Docker Desktop Kubernetes..."
    
    if command_exists docker; then
        echo -e "${GREEN}✅ Docker is installed${NC}"
        echo ""
        echo "To enable Kubernetes in Docker Desktop:"
        echo "1. Open Docker Desktop"
        echo "2. Go to Settings/Preferences → Kubernetes"
        echo "3. Check 'Enable Kubernetes'"
        echo "4. Click 'Apply & Restart'"
        echo ""
        echo "After enabling, run this script again to verify the setup."
    else
        echo -e "${RED}❌ Docker not found${NC}"
        echo "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    fi
}

# Function to setup minikube
setup_minikube() {
    echo "🎯 Setting up minikube..."
    
    if command_exists minikube; then
        echo -e "${GREEN}✅ minikube is installed${NC}"
        
        echo "🚀 Starting minikube cluster..."
        minikube start --driver=docker --memory=4096 --cpus=2
        
        echo "🔧 Configuring kubectl context..."
        kubectl config use-context minikube
        
        echo "✅ minikube cluster is ready!"
    else
        echo -e "${RED}❌ minikube not found${NC}"
        echo ""
        echo "To install minikube:"
        echo "📥 macOS: brew install minikube"
        echo "📥 Linux: curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64"
        echo "📥 Windows: Download from https://minikube.sigs.k8s.io/docs/start/"
    fi
}

# Function to setup Kind
setup_kind() {
    echo "🎪 Setting up Kind (Kubernetes in Docker)..."
    
    if command_exists kind; then
        echo -e "${GREEN}✅ Kind is installed${NC}"
        
        # Create cluster configuration
        cat > kind-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: core-bank
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
- role: worker
- role: worker
EOF
        
        echo "🚀 Creating Kind cluster..."
        kind create cluster --config kind-config.yaml
        
        echo "🔧 Configuring kubectl context..."
        kubectl config use-context kind-core-bank
        
        echo "✅ Kind cluster is ready!"
        
        # Clean up config file
        rm kind-config.yaml
    else
        echo -e "${RED}❌ Kind not found${NC}"
        echo ""
        echo "To install Kind:"
        echo "📥 macOS: brew install kind"
        echo "📥 Linux: curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64"
        echo "📥 Windows: Download from https://kind.sigs.k8s.io/docs/user/quick-start/"
    fi
}

# Function to install kubectl
install_kubectl() {
    echo "⚙️ Installing kubectl..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command_exists brew; then
            brew install kubectl
        else
            echo "Installing kubectl via curl..."
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
            chmod +x kubectl
            sudo mv kubectl /usr/local/bin/
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    else
        echo "Please install kubectl manually from: https://kubernetes.io/docs/tasks/tools/"
    fi
}

# Function to verify setup
verify_setup() {
    echo "✅ Verifying cluster setup..."
    
    echo "🔍 Cluster info:"
    kubectl cluster-info
    
    echo ""
    echo "🔍 Node status:"
    kubectl get nodes
    
    echo ""
    echo "🔍 System pods:"
    kubectl get pods -n kube-system
    
    echo ""
    echo -e "${GREEN}🎉 Cluster verification complete!${NC}"
}

# Main menu
show_menu() {
    echo ""
    echo "Choose your Kubernetes setup option:"
    echo "1) Docker Desktop Kubernetes (Recommended for Mac/Windows)"
    echo "2) minikube (Cross-platform)"
    echo "3) Kind (Kubernetes in Docker)"
    echo "4) Check current cluster status"
    echo "5) Install kubectl"
    echo "6) Verify cluster setup"
    echo "7) Exit"
    echo ""
}

# Main execution
main() {
    # Check if kubectl is installed
    if ! command_exists kubectl; then
        echo -e "${YELLOW}⚠️  kubectl not found${NC}"
        read -p "Would you like to install kubectl? (y/n): " install_kb
        if [[ $install_kb =~ ^[Yy]$ ]]; then
            install_kubectl
        else
            echo "kubectl is required. Please install it manually and run this script again."
            exit 1
        fi
    fi
    
    # Check current cluster status
    if check_cluster; then
        echo ""
        echo -e "${GREEN}✅ Your cluster is ready for Core Bank deployment!${NC}"
        echo "Run: ./deploy.sh to deploy the Core Bank services"
        exit 0
    fi
    
    # Show setup options
    while true; do
        show_menu
        read -p "Enter your choice (1-7): " choice
        
        case $choice in
            1)
                setup_docker_desktop
                ;;
            2)
                setup_minikube
                break
                ;;
            3)
                setup_kind
                break
                ;;
            4)
                check_cluster
                ;;
            5)
                install_kubectl
                ;;
            6)
                verify_setup
                ;;
            7)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please choose 1-7.${NC}"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
    
    # Verify setup after cluster creation
    echo ""
    echo "🔄 Waiting for cluster to be ready..."
    sleep 10
    
    if check_cluster; then
        verify_setup
        echo ""
        echo -e "${GREEN}🎉 Cluster setup complete!${NC}"
        echo "You can now run: ./deploy.sh to deploy Core Bank services"
    else
        echo -e "${RED}❌ Cluster setup failed. Please check the output above for errors.${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
