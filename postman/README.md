# Core Bank Postman Collections

This directory contains Postman collections and environments for testing the Core Bank microservices in different deployment scenarios.

## 📁 Collections

### 1. CoreBank-Docker-Compose.postman_collection.json
- **Purpose**: For testing services deployed via Docker Compose
- **Endpoints**: Uses localhost with service-specific ports
- **Environment**: Use with Docker Compose environment files

### 2. CoreBank-Kubernetes.postman_collection.json
- **Purpose**: For testing services deployed in Kubernetes cluster
- **Endpoints**: Uses Ingress-based domain names (*.core-bank.local)
- **Environment**: Use with Kubernetes environment files

### 3. CoreBank.postman_collection.json
- **Purpose**: Legacy collection (deprecated - use specific collections above)

## 🌍 Environments

### Docker Compose Environments
- `Docker-Compose-Admin-Core-Banking.postman_environment.json`
- `Docker-Compose-Client-Core-Banking.postman_environment.json`

### Kubernetes Environments
- `Kubernetes-Admin-Core-Banking.postman_environment.json`
- `Kubernetes-Client-Core-Banking.postman_environment.json`

### Legacy Environments
- `Admin-Core-Banking.postman_environment.json`
- `Client-Core-Banking.postman_environment.json`

## 🚀 Quick Start

### For Docker Compose Deployment

1. **Import Collection**: `CoreBank-Docker-Compose.postman_collection.json`
2. **Import Environment**: 
   - For admin operations: `Docker-Compose-Admin-Core-Banking.postman_environment.json`
   - For client operations: `Docker-Compose-Client-Core-Banking.postman_environment.json`
3. **Select Environment**: Choose the imported environment in Postman
4. **Start Services**: Ensure Docker Compose services are running
5. **Test**: Run the "Complete Workflow" folder for end-to-end testing

### For Kubernetes Deployment

1. **Setup Ingress**: Ensure NGINX Ingress Controller is installed and configured
2. **Configure /etc/hosts**: Add entries for Ingress domains:
   ```bash
   # Add to /etc/hosts (replace <INGRESS_IP> with your ingress controller IP)
   <INGRESS_IP> account.core-bank.local
   <INGRESS_IP> customer.core-bank.local
   <INGRESS_IP> transaction.core-bank.local
   <INGRESS_IP> auth.core-bank.local
   <INGRESS_IP> discovery.core-bank.local
   ```
3. **Import Collection**: `CoreBank-Kubernetes.postman_collection.json`
4. **Import Environment**:
   - For admin operations: `Kubernetes-Admin-Core-Banking.postman_environment.json`
   - For client operations: `Kubernetes-Client-Core-Banking.postman_environment.json`
5. **Select Environment**: Choose the imported environment in Postman
6. **Deploy Services**: Ensure Kubernetes services are deployed and healthy
7. **Test**: Run the "Complete Workflow" folder for end-to-end testing

## 🔧 Service Endpoints

### Docker Compose (localhost)
| Service | Port | Health Check |
|---------|------|-------------|
| Discovery Service (Eureka) | 8761 | http://localhost:8761/actuator/health |
| Account Service | 8081 | http://localhost:8081/actuator/health |
| Transaction Service | 8082 | http://localhost:8082/actuator/health |
| Customer Service | 8083 | http://localhost:8083/actuator/health |
| Authentication Service | 8084 | http://localhost:8084/actuator/health |

### Kubernetes (Ingress)
| Service | Domain | Health Check |
|---------|--------|-------------|
| Discovery Service | discovery.core-bank.local | http://discovery.core-bank.local/actuator/health |
| Account Service | account.core-bank.local | http://account.core-bank.local/actuator/health |
| Transaction Service | transaction.core-bank.local | http://transaction.core-bank.local/actuator/health |
| Customer Service | customer.core-bank.local | http://customer.core-bank.local/actuator/health |
| Authentication Service | auth.core-bank.local | http://auth.core-bank.local/actuator/health |

## 🔐 Authentication

Both collections include admin and client authentication:

### Admin Credentials
- **Email**: admin@example.com
- **Password**: SecureAdminP@ssw0rd!

### Client Credentials
- **Email**: john.doe@example.com
- **Password**: 123456

## 📋 Testing Workflow

### Complete Workflow (Recommended)
The collections include a "Complete Workflow" folder that demonstrates the full customer journey:

1. **Admin Login** - Authenticate as admin
2. **Create Customer** - Create a new customer record
3. **Create Account** - Create a bank account for the customer
4. **Make Deposit** - Deposit money into the account
5. **Check Balance** - Verify the account balance

### Individual Service Testing
Each service has its own folder with specific operations:

- **🔐 Authentication Service**: Login, token validation, health checks
- **👤 Customer Service**: CRUD operations for customer management
- **🏦 Account Service**: Account creation, balance checks, status updates
- **💰 Transaction Service**: Deposits, withdrawals, transfers, transaction history
- **🔍 Discovery Service**: Service registry status, Eureka dashboard

## 🔄 Variables and Automation

The collections use variables for dynamic testing:

### Collection Variables
- `authToken`: Automatically set after successful login
- `customerId`: Automatically set after customer creation
- `accountNumber`: Automatically set after account creation
- `email`: Default customer email
- `phoneNumber`: Default customer phone number

### Environment Variables
- Service URLs (different for Docker Compose vs Kubernetes)
- Base URLs and ports
- Default credentials

## 🛠️ Troubleshooting

### Common Issues

1. **Connection Refused**
   - **Docker Compose**: Ensure all services are running with `docker-compose ps`
   - **Kubernetes**: Check pod status with `kubectl get pods -n core-bank`

2. **Authentication Failures**
   - Verify credentials in environment variables
   - Check if authentication service is healthy
   - Ensure token is being saved correctly (check Tests tab)

3. **Ingress Issues (Kubernetes)**
   - Verify /etc/hosts entries
   - Check Ingress Controller status: `kubectl get pods -n ingress-nginx`
   - Validate Ingress rules: `kubectl get ingress -n core-bank`

4. **Service Discovery Issues**
   - Check Eureka dashboard at discovery service endpoint
   - Verify all services are registered
   - Check service logs for connection issues

### Health Check Debugging

Use the health check endpoints in each service folder to verify:
- Service is running
- Dependencies are available
- Database connections are healthy

## 📊 Monitoring and Observability

For Kubernetes deployments, additional monitoring endpoints are available:

- **Grafana**: http://grafana.core-bank.local
- **Prometheus**: http://prometheus.core-bank.local

## 🎯 Best Practices

1. **Environment Selection**: Always select the correct environment before testing
2. **Sequential Testing**: Run authentication first, then customer/account creation
3. **Variable Management**: Check that variables are being set correctly in the Tests tab
4. **Health Checks**: Verify service health before running business operations
5. **Error Handling**: Check response status and error messages for troubleshooting

## 📝 Notes

- Collections include automatic token management
- Variables are shared across requests for seamless workflows
- Health check endpoints don't require authentication
- Service URLs are environment-specific for easy switching between deployments
- All collections support both admin and client user types

For more information about the Core Bank system architecture and deployment, see the main README.md file in the project root.
