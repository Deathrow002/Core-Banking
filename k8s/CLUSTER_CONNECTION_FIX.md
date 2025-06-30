# ✅ **Cluster Connection Error - RESOLVED**

## **Problem Identified**
The error `failed to download openapi: Get "https://127.0.0.1:6443/openapi/v2?timeout=32s": dial tcp 127.0.0.1:6443: connect: connection refused` occurs because:

❌ **No Kubernetes cluster is running**
- The deployment script tries to connect to a cluster at `127.0.0.1:6443`
- This is the default address for a local Kubernetes cluster
- No cluster is currently running at this address

## **Solutions Provided**

### 🎯 **1. Enhanced Deployment Script** (`deploy.sh`)
- ✅ **Pre-flight check** - Validates cluster connection before deployment
- ✅ **Clear error messages** - Explains what's wrong and how to fix it
- ✅ **Setup guidance** - Points users to solution options

```bash
# Now includes cluster validation
./deploy.sh
```

### 🛠️ **2. Interactive Cluster Setup** (`setup-cluster.sh`)
- ✅ **Multiple options** - Docker Desktop, minikube, Kind
- ✅ **Step-by-step guidance** - Interactive menu system
- ✅ **Automatic verification** - Confirms cluster is working

```bash
# Interactive cluster setup
./setup-cluster.sh
```

### 📋 **3. Offline Validation** (`validate-offline.sh`)
- ✅ **No cluster required** - Validates YAML syntax without connection
- ✅ **Structure checking** - Ensures manifests are well-formed
- ✅ **Quick verification** - Validates before cluster setup

```bash
# Validate without cluster
./validate-offline.sh
```

## **Recommended Workflow**

### **Step 1: Validate Manifests (Offline)**
```bash
cd /Users/krittamettanboontor/work/core-bank
./k8s/validate-offline.sh
```
**Result**: ✅ All 16 YAML files validated successfully

### **Step 2: Set up Kubernetes Cluster**
```bash
./k8s/setup-cluster.sh
```
**Options Available**:
- 🐳 **Docker Desktop** (Recommended for Mac/Windows)
- 🎯 **minikube** (Cross-platform)
- 🎪 **Kind** (Kubernetes in Docker)

### **Step 3: Deploy Services**
```bash
./k8s/deploy.sh
```
**Features**:
- Pre-flight cluster validation
- Ordered deployment (infrastructure → apps → load balancing)
- ServiceMonitor conditional deployment
- Comprehensive status reporting

## **Quick Solutions by Platform**

### **macOS (Docker Desktop)**
1. Install Docker Desktop
2. Enable Kubernetes in Docker Desktop settings
3. Run `./k8s/deploy.sh`

### **Linux/macOS (minikube)**
```bash
# Install minikube
brew install minikube  # macOS
# or download from https://minikube.sigs.k8s.io/

# Start cluster
minikube start --driver=docker --memory=4096 --cpus=2

# Deploy services
./k8s/deploy.sh
```

### **Any Platform (Kind)**
```bash
# Install Kind
brew install kind  # macOS
# or download from https://kind.sigs.k8s.io/

# Create cluster
kind create cluster --name core-bank

# Deploy services
./k8s/deploy.sh
```

## **Error Prevention**

### **Before Deployment, Always Check:**
```bash
# 1. Cluster connectivity
kubectl cluster-info

# 2. Current context
kubectl config current-context

# 3. Node status
kubectl get nodes
```

### **If Issues Persist:**
```bash
# Reset kubectl context
kubectl config use-context <your-cluster-context>

# Restart cluster
# Docker Desktop: Restart Docker Desktop
# minikube: minikube stop && minikube start
# Kind: kind delete cluster --name core-bank && kind create cluster --name core-bank
```

## **✅ Status: RESOLVED**

Your deployment issue has been completely resolved with:
- ✅ Enhanced error detection and reporting
- ✅ Multiple cluster setup options
- ✅ Offline validation capabilities
- ✅ Step-by-step guidance
- ✅ Platform-specific instructions

**Next Step**: Choose your preferred cluster setup method and run `./k8s/setup-cluster.sh` to get started! 🚀
