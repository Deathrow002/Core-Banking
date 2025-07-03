# 🚀 Quick Deployment Guide

This guide shows you how to deploy the Core Bank System with monitoring using the provided deployment scripts.

## 📋 Prerequisites

- **Docker** and **Docker Compose** installed
- **8GB+ RAM** recommended
- **Ports available**: 3000, 5432, 6379, 8081-8084, 9090, 9092

## 🎯 One-Command Deployment

### Full Deployment (Recommended)
```bash
# Deploy everything including Grafana dashboards
./deploy.sh
```

### Quick Deployment Options
```bash
# Skip cleanup (faster for development)
./deploy.sh --skip-cleanup

# Deploy without Grafana dashboards
./deploy.sh --skip-dashboards

# Get help
./deploy.sh --help
```

## 📊 Dashboard-Only Setup

If you already have the system running and just want to set up Grafana dashboards:

```bash
# Setup Grafana dashboards only
./setup-grafana.sh

# With custom credentials
./setup-grafana.sh --username admin --password secret

# With custom Grafana URL
./setup-grafana.sh --grafana-url http://my-grafana:3000
```

## 🔧 Manual Deployment Steps

If you prefer manual control:

### 1. Start Infrastructure
```bash
docker-compose up -d postgres redis kafka
sleep 30  # Wait for services to initialize
```

### 2. Start Monitoring
```bash
docker-compose up -d prometheus grafana
sleep 20  # Wait for services to start
```

### 3. Start Discovery Service
```bash
docker-compose up -d discovery-service
sleep 30  # Wait for Eureka to start
```

### 4. Start Core Services
```bash
docker-compose up -d authentication-service account-service customer-service transaction-service
```

### 5. Setup Grafana Dashboards
```bash
./setup-grafana.sh
```

## 🌐 Access URLs

After deployment, access these services:

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://localhost:3000 | `myuser` / `mypassword` |
| **Prometheus** | http://localhost:9090 | No auth |
| **Discovery Service** | http://localhost:8761 | No auth |
| **Account API** | http://localhost:8081 | JWT required |
| **Customer API** | http://localhost:8083 | JWT required |
| **Transaction API** | http://localhost:8082 | JWT required |
| **Authentication API** | http://localhost:8084 | No auth |

## 📊 Grafana Dashboards

Three dashboards are automatically imported:

### 1. 📈 Core Bank Overview
- System-wide health and performance
- Service availability and response times
- Resource usage (CPU, Memory)
- Error rates across all services

### 2. 🔍 Service Details
- Individual service metrics
- JVM performance (heap, threads)
- Database connection pools
- Detailed performance breakdowns

### 3. 💰 Business Metrics
- Banking operation counts
- Transaction volumes and types
- Customer activity metrics
- Business KPIs and trends

## 🧪 Testing Your Deployment

### Health Checks
```bash
# Check all services
docker-compose ps

# Test individual services
curl http://localhost:8081/actuator/health    # Account Service
curl http://localhost:8083/actuator/health    # Customer Service
curl http://localhost:8082/actuator/health    # Transaction Service
curl http://localhost:8084/actuator/health    # Authentication Service
```

### Generate Test Data
```bash
# Use Postman collection
# Import: postman/CoreBank-Docker-Compose.postman_collection.json

# Or use curl commands
curl -X POST http://localhost:8084/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password"}'
```

## 🔧 Useful Commands

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f grafana
docker-compose logs -f account-service
```

### Restart Services
```bash
# Restart specific service
docker-compose restart grafana

# Restart all
docker-compose restart
```

### Stop Services
```bash
# Stop all
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Port Already in Use
```bash
# Check what's using the port
lsof -i :3000

# Kill the process or change ports in docker-compose.yml
```

#### 2. Services Not Starting
```bash
# Check logs
docker-compose logs [service-name]

# Check resources
docker system df
docker system prune  # Clean up if needed
```

#### 3. Grafana Dashboard Issues
```bash
# Re-run dashboard setup
./setup-grafana.sh

# Check Grafana logs
docker-compose logs grafana

# Manually import dashboards via UI
```

#### 4. No Data in Dashboards
```bash
# Check Prometheus targets
curl http://localhost:9090/targets

# Verify service metrics endpoints
curl http://localhost:8081/actuator/prometheus
```

### Getting Help

1. **Check service logs**: `docker-compose logs [service-name]`
2. **Verify network connectivity**: `docker network ls`
3. **Check resource usage**: `docker stats`
4. **Review configuration**: Check `docker-compose.yml`

## 📚 Next Steps

1. **Import Postman Collection**: `postman/CoreBank-Docker-Compose.postman_collection.json`
2. **Explore Grafana Dashboards**: Start with "Core Bank Overview"
3. **Test API Endpoints**: Use the authentication flow to get JWT tokens
4. **Monitor Performance**: Generate load and watch metrics in real-time
5. **Customize Dashboards**: Add your own metrics and panels

## 🎉 Success!

Your Core Bank System is now running with full monitoring capabilities. Start exploring the APIs and dashboards to see your banking system in action!
