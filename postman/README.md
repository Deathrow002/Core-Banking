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
   # Add to /etc/hosts (replace with 127.0.0.1 for local Kubernetes)
   127.0.0.1 account.core-bank.local
   127.0.0.1 customer.core-bank.local
   127.0.0.1 transaction.core-bank.local
   127.0.0.1 auth.core-bank.local
   127.0.0.1 discovery.core-bank.local
   127.0.0.1 grafana.core-bank.local
   127.0.0.1 prometheus.core-bank.local
   ```
3. **Import Collection**: `CoreBank-Kubernetes.postman_collection.json`
4. **Import Environment**:
   - For admin operations: `Kubernetes-Admin-Core-Banking.postman_environment.json`
   - For client operations: `Kubernetes-Client-Core-Banking.postman_environment.json`
5. **Select Environment**: Choose the imported environment in Postman
6. **Deploy Services**: Ensure Kubernetes services are deployed and healthy
7. **Test**: Run the "Complete Workflow" folder for end-to-end testing

**Note**: The Kubernetes collection has been updated to use the correct authentication endpoint format (query parameters instead of JSON body).

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
| Service | Domain | Health Check | Key Endpoints |
|---------|--------|-------------|---------------|
| Discovery Service | discovery.core-bank.local | http://discovery.core-bank.local/actuator/health | Dashboard: `/`, Registry: `/eureka/apps` |
| Account Service | account.core-bank.local | http://account.core-bank.local/actuator/health | Create: `/accounts/createAccount`, Get: `/accounts/getAccount`, All: `/accounts/getAllAccounts` |
| Transaction Service | transaction.core-bank.local | http://transaction.core-bank.local/actuator/health | Deposit: `/transactions/deposit`, Withdraw: `/transactions/withdraw`, Transfer: `/transactions/Transaction` |
| Customer Service | customer.core-bank.local | http://customer.core-bank.local/actuator/health | CRUD: `/customers`, All: `/customers/all` |
| Authentication Service | auth.core-bank.local | http://auth.core-bank.local/actuator/health* | Login: `/api/v1/auth/login`, Register: `/api/v1/auth/register`, Validate: `/api/v1/auth/validate` |

*Note: Authentication service health endpoint may return 401 due to security configuration. Use TCP probe for health checks.

## 🔐 Authentication

Both collections include admin and client authentication with proper endpoint configuration:

### Authentication Method
- **Docker Compose**: Uses query parameters for login endpoints
- **Kubernetes**: Uses query parameters for login endpoints (recently updated)
- **Endpoint**: `/api/v1/auth/login?email=<email>&password=<password>`

### Admin Credentials
- **Email**: admin@example.com
- **Password**: SecureAdminP@ssw0rd!

### Client Credentials
- **Email**: john.doe@example.com
- **Password**: 123456

### Authentication Endpoints
- **Login**: `POST /api/v1/auth/login` (with query parameters)
- **Register**: `POST /api/v1/auth/register` (with JSON body)
- **Validate Token**: `GET /api/v1/auth/validate` (with Bearer token)

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

- **🔐 Authentication Service**: 
  - Admin Login, Client Login
  - User Registration (JSON body)
  - Token validation and health checks
  - Enhanced debugging with detailed console logging
- **👤 Customer Service**: 
  - CRUD operations for customer management
  - Get all customers, customer by ID
  - Update and delete customer records
- **🏦 Account Service**: 
  - Account creation (`/accounts/createAccount` with AccountDTO)
  - Get account by ID (`/accounts/getAccount?accNo={uuid}`)
  - Get all accounts (`/accounts/getAllAccounts` - Admin only)
  - Get accounts by customer ID
  - Balance checks, status updates
- **💰 Transaction Service**: 
  - Deposits (`/transactions/deposit`)
  - Withdrawals (`/transactions/withdraw`) 
  - Transfers (`/transactions/Transaction`)
  - Transaction history by account
- **🔍 Discovery Service**: 
  - Service registry status
  - Eureka dashboard access

## 🔄 Variables and Automation

The collections use variables for dynamic testing:

### Collection Variables
- `authToken`: Automatically set after successful login (saved to **environment** variables)
- `customerId`: Automatically set after customer creation
- `accountNumber`: Automatically set after account creation (uses `accountId` from response)
- `email`: Default customer email
- `phoneNumber`: Default customer phone number

### Environment Variables
- Service URLs (different for Docker Compose vs Kubernetes)
- Base URLs and ports
- Default credentials
- `authToken`: JWT token storage for API authentication

### Key Variable Updates (Kubernetes Collection)
- Authentication token now properly saved to environment variables instead of collection variables
- Account creation returns `accountId` (UUID) which is saved as `accountNumber` variable
- Enhanced error handling and console logging for debugging
- Account endpoints updated to use correct service paths (`/accounts/createAccount`, `/accounts/getAccount`, etc.)

## 🛠️ Troubleshooting

### Common Issues

1. **Connection Refused**
   - **Docker Compose**: Ensure all services are running with `docker-compose ps`
   - **Kubernetes**: Check pod status with `kubectl get pods -n core-bank`

2. **Authentication Failures**
   - Verify credentials in environment variables
   - Check if authentication service is healthy
   - Ensure token is being saved correctly to **environment variables** (check Postman Console for logs)
   - **Kubernetes**: Use query parameters for login: `?email=<email>&password=<password>`
   - **Docker Compose**: Use query parameters for login: `?email=<email>&password=<password>`
   - Check Postman Console (View → Show Postman Console) for detailed authentication debugging

3. **Account Service Issues**
   - Verify correct endpoints: `/accounts/createAccount` for creation, `/accounts/getAccount?accNo={uuid}` for retrieval
   - Ensure request body matches AccountDTO format: `{"customerId": "uuid", "balance": number, "currency": "USD|THB|SGD|JPY|CNY|GBP|EUR"}`
   - Check that `accountId` (UUID) is being extracted correctly from responses
   - Admin role required for `/accounts/getAllAccounts` endpoint

3. **Ingress Issues (Kubernetes)**
   - Verify /etc/hosts entries
   - Check Ingress Controller status: `kubectl get pods -n ingress-nginx`
   - Validate Ingress rules: `kubectl get ingress -n core-bank`

4. **Service Discovery Issues**
   - Check Eureka dashboard at discovery service endpoint
   - Verify all services are registered
   - Check service logs for connection issues

5. **Transaction Service Issues**
   - Verify correct endpoints: `/transactions/deposit`, `/transactions/withdraw`, `/transactions/Transaction`
   - Ensure request body format matches service expectations
   - Check account ID format (UUID) in transaction requests

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
3. **Variable Management**: Check that variables are being set correctly in the Tests tab and Postman Console
4. **Health Checks**: Verify service health before running business operations
5. **Error Handling**: Check response status and error messages for troubleshooting
6. **Console Debugging**: Use Postman Console (View → Show Postman Console) to see detailed logs
7. **Account Management**: Remember that account operations use UUID-based `accountId`, not sequential account numbers
8. **Admin Permissions**: Use Admin login for operations requiring elevated privileges (e.g., Get All Accounts)
9. **Service-Specific Endpoints**: Use correct service-specific paths rather than generic REST endpoints

## 📝 Notes

- Collections include automatic token management with JWT Bearer authentication
- Variables are shared across requests for seamless workflows
- Health check endpoints don't require authentication (except auth service which may return 401)
- Service URLs are environment-specific for easy switching between deployments
- All collections support both admin and client user types
- **Authentication endpoints use query parameters**, not JSON body
- Kubernetes collection updated (July 2025) to fix authentication endpoint format
- Register endpoint uses JSON body, login endpoint uses query parameters

## 🔄 Recent Updates (July 2025)

- ✅ **Fixed Authentication Token Storage**: Changed from collection variables to environment variables for proper token persistence
- ✅ **Corrected Account Service Endpoints**: Updated to use actual controller paths (`/accounts/createAccount`, `/accounts/getAccount?accNo={uuid}`)
- ✅ **Added Get All Accounts Endpoint**: New admin-only endpoint for retrieving all accounts in the system
- ✅ **Enhanced Authentication Debugging**: Added comprehensive console logging for login troubleshooting
- ✅ **Updated Account Data Model**: Account creation now uses `accountId` (UUID) instead of sequential account numbers
- ✅ **Fixed Request/Response Mapping**: Updated test scripts to extract `accountId` from account creation responses
- ✅ **Verified Transaction Service Integration**: Updated transaction endpoints to work with UUID-based account IDs
- ✅ **Enhanced Error Handling**: Added try-catch blocks and detailed error messages in test scripts
- ✅ **Updated Service Documentation**: Comprehensive endpoint documentation with correct paths and parameters
- ✅ Fixed Kubernetes authentication endpoints to use query parameters
- ✅ Updated /etc/hosts configuration with 127.0.0.1 for local development
- ✅ Added Register User endpoint to Kubernetes collection
- ✅ Corrected authentication service endpoint paths to `/api/v1/auth/*`
- ✅ Enhanced troubleshooting section with authentication-specific guidance

For more information about the Core Bank system architecture and deployment, see the main README.md file in the project root.
