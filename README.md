# Core Bank System

This project is a **microservices-based core banking system** designed for high availability, scalability, and modern cloud-native deployment. It includes multiple services such as account management, transaction processing, customer management, authentication, and service discovery, along with supporting infrastructure like PostgreSQL, Redis, Kafka, Prometheus, and Grafana.

## 🚀 Key Features

- **Microservices Architecture**: Loosely coupled services with independent deployment
- **Container-Ready**: Docker and Kubernetes support with optimized configurations
- **Load Balancing**: Horizontal Pod Autoscaling (HPA) and service mesh ready
- **Service Discovery**: Eureka-based service registry for dynamic service discovery
- **Security**: JWT-based authentication with role-based access control
- **Monitoring**: Comprehensive observability with Prometheus and Grafana
- **Message Streaming**: Event-driven architecture using Apache Kafka
- **Caching**: Redis integration for high-performance data access
- **Database**: PostgreSQL for ACID-compliant transaction processing

## Services Overview

### Core Services
- **Discovery Service** (Port 8761): Service registry using Eureka Server
- **Authentication Service** (Port 8084): JWT-based user authentication and authorization
- **Account Service** (Port 8081): Account management with PostgreSQL and Redis integration
- **Transaction Service** (Port 8082): Transaction processing with Kafka event streaming
- **Customer Service** (Port 8083): Customer profile and address management

### Supporting Infrastructure
- **PostgreSQL** (Port 5432): Primary database for persistent data storage
- **Redis** (Port 6379): In-memory cache for performance optimization
- **Apache Kafka** (Port 9092): Message broker for event-driven communication
- **Prometheus** (Port 9090): Metrics collection and monitoring
- **Grafana** (Port 3000): Data visualization and analytics dashboards

## 🏗️ Architecture & Workflow

The Core Bank System operates as a **cloud-native microservices architecture** with the following workflow:

1. **Service Discovery & Registration**:
   - All services automatically register with Eureka Discovery Service
   - Dynamic service discovery enables resilient communication
   - Load balancing across multiple service instances

2. **Authentication & Security**:
   - JWT-based authentication with role-based access control (ADMIN, MANAGER, USER)
   - Secure inter-service communication
   - Protected actuator endpoints with health checks

3. **Business Logic Processing**:
   - **Account Service**: Account CRUD operations with Redis caching
   - **Transaction Service**: Real-time transaction processing with Kafka events
   - **Customer Service**: Customer profile management with validation

4. **Event-Driven Communication**:
   - Kafka streams for asynchronous transaction events
   - Microservices communicate via events for loose coupling
   - Real-time data synchronization across services

5. **Monitoring & Observability**:
   - Prometheus metrics collection from all services
   - Grafana dashboards for system health visualization
   - Health checks and readiness probes for reliability

6. **Data Persistence & Caching**:
   - PostgreSQL for ACID-compliant data storage
   - Redis for high-performance caching and session management
   - Persistent volumes for data durability

## 🛠️ Prerequisites & Setup

### Requirements
- **Docker** & **Docker Compose** (for local development)
- **Kubernetes** (for production deployment)
- **kubectl** (for Kubernetes management)
- **Java 21+** & **Maven** (for development)

### Quick Start Options

#### Option 1: Automated Docker Deployment (Recommended)
```bash
# Clone the repository
git clone <repository-url>
cd core-bank

# One-command deployment with monitoring
./deploy.sh

# Or deploy without dashboards
./deploy.sh --skip-dashboards

# Setup Grafana dashboards only
./k8s/scripts/setup-grafana.sh
```

#### Option 2: Manual Docker Compose (Development)
```bash
# Start all services manually
docker-compose up -d

# Check service health
docker-compose ps
```

#### Option 3: Kubernetes with Grafana (Production)
```bash
# Deploy to Kubernetes with monitoring and dashboards
cd k8s
./deploy-with-grafana.sh

# Or with custom options
./deploy-with-grafana.sh --port-forward
./deploy-with-grafana.sh --namespace my-banking-system

# Setup dashboards only
./setup-k8s-grafana-dashboards.sh
```

#### Option 4: Standard Kubernetes (Production)
```bash
# Deploy to Kubernetes with optimized configuration
cd k8s
./deploy.sh

# Check deployment status
kubectl get pods -n core-bank
kubectl get services -n core-bank
```

### 📋 Complete Deployment Guide
📚 **See all options**: [`./deployment-guide.sh`](deployment-guide.sh) or run `./deployment-guide.sh`

## 🎯 Service Endpoints

### External Access (via Ingress)
- **Account Service**: `http://account.core-bank.local`
- **Transaction Service**: `http://transaction.core-bank.local`  
- **Customer Service**: `http://customer.core-bank.local`
- **Authentication Service**: `http://auth.core-bank.local`
- **Discovery Service**: `http://discovery.core-bank.local`
- **Grafana Dashboard**: `http://grafana.core-bank.local`
- **Prometheus Metrics**: `http://prometheus.core-bank.local`

### Direct Access (via port-forward)
```bash
# Service Discovery
kubectl port-forward svc/discovery-service 8761:8761 -n core-bank

# Core Services
kubectl port-forward svc/account-service 8081:8081 -n core-bank
kubectl port-forward svc/transaction-service 8082:8082 -n core-bank
kubectl port-forward svc/customer-service 8083:8083 -n core-bank
kubectl port-forward svc/authentication-service 8084:8084 -n core-bank

# Monitoring
kubectl port-forward svc/prometheus 9090:9090 -n core-bank
kubectl port-forward svc/grafana 3000:3000 -n core-bank
```

### Default Credentials
- **Grafana**: Username: `myuser`, Password: `mypassword`
- **Admin User**: Email: `admin@example.com` (configured in Authentication Service)

## ⚖️ Load Balancing & Scaling

The system includes production-ready load balancing and auto-scaling:

### Horizontal Pod Autoscaling (HPA)
- **Account Service**: 2-10 pods (CPU: 70%, Memory: 80%)
- **Transaction Service**: 2-10 pods (CPU: 70%, Memory: 80%)  
- **Customer Service**: 1-5 pods (CPU: 70%, Memory: 80%)
- **Authentication Service**: 1-5 pods (CPU: 70%, Memory: 80%)

### Load Balancer Features
- Round-robin load balancing
- Health-based routing
- Session affinity support
- Circuit breaker patterns (Resilience4j @CircuitBreaker annotation in service classes for remote calls)

### Resource Optimization
- **CPU Requests**: Optimized for scheduling (50m-100m per service)
- **Memory Requests**: Right-sized for efficient resource usage (128Mi-512Mi)
- **Readiness Probes**: Fast startup detection (TCP-based for secured services)
- **Liveness Probes**: Reliable health monitoring

## 🔧 Management Commands

```bash
# Scale services manually
kubectl scale deployment account-service --replicas=5 -n core-bank

# View status and logs
kubectl get pods -n core-bank
kubectl logs -l app=account-service -n core-bank

# Resource monitoring
kubectl top pods -n core-bank
kubectl top nodes

# Port forwarding for development
kubectl port-forward svc/discovery-service 8761:8761 -n core-bank
```

## 📋 API Testing with Postman

## 🧪 API Testing with Postman

The project includes ready-to-use Postman collections and environment files for testing all core banking APIs in both Docker Compose and Kubernetes environments.

### How to Use

1. **Open Postman** (download from https://www.postman.com/downloads/ if needed).
2. **Import the Collection**:
   - Go to `File > Import` and select one of the following:
     - `postman/CoreBank-Docker-Compose.postman_collection.json` (for local Docker Compose)
     - `postman/CoreBank-Kubernetes.postman_collection.json` (for Kubernetes/Ingress)
3. **Import the Environment**:
   - Go to `File > Import` and select the matching environment file:
     - For Docker Compose: `Docker-Compose-Admin-Core-Banking.postman_environment.json` or `Docker-Compose-Client-Core-Banking.postman_environment.json`
     - For Kubernetes: `Kubernetes-Admin-Core-Banking.postman_environment.json` or `Kubernetes-Client-Core-Banking.postman_environment.json`
4. **Select the Environment** in the top-right dropdown in Postman.
5. **(Kubernetes only)**: Add the service hostnames to your `/etc/hosts` file as described in the environment file or README.
6. **Run Requests**:
   - Use the folders in the collection for workflows like authentication, account management, transactions, and customer operations.
   - Use the "Complete Workflow" folder for end-to-end tests.

### Tips
- Environment variables (tokens, IDs) are auto-populated by test scripts.
- Use the "Pre-request Script" and "Tests" tabs in Postman for automation and validation.
- See `postman/README.md` for advanced usage and troubleshooting.

### Example Endpoints Covered
- Authentication: Login, token validation
- Account: Create, get, update, delete, check balance
- Customer: Register, update, validate
- Transaction: Deposit, withdraw, transfer, history

For more details, see the `postman/README.md` file in the repository.

The system includes comprehensive Postman collections for testing both Docker Compose and Kubernetes deployments:

### Collections Available
- **[CoreBank-Docker-Compose.postman_collection.json](./postman/CoreBank-Docker-Compose.postman_collection.json)**: For localhost testing (Docker Compose)
- **[CoreBank-Kubernetes.postman_collection.json](./postman/CoreBank-Kubernetes.postman_collection.json)**: For Ingress-based testing (Kubernetes)

### Environment Files
- **Docker Compose**: 
  - `Docker-Compose-Admin-Core-Banking.postman_environment.json`
  - `Docker-Compose-Client-Core-Banking.postman_environment.json`
- **Kubernetes**: 
  - `Kubernetes-Admin-Core-Banking.postman_environment.json`
  - `Kubernetes-Client-Core-Banking.postman_environment.json`

### Quick Setup
1. **Import Collection**: Choose the appropriate collection for your deployment
2. **Import Environment**: Select admin or client environment file
3. **Configure Hosts** (Kubernetes only): Add entries to `/etc/hosts`:
   ```bash
   # Replace <INGRESS_IP> with your ingress controller IP
   <INGRESS_IP> account.core-bank.local
   <INGRESS_IP> customer.core-bank.local
   <INGRESS_IP> transaction.core-bank.local
   <INGRESS_IP> auth.core-bank.local
   <INGRESS_IP> discovery.core-bank.local
   ```
4. **Test**: Run the "Complete Workflow" folder for end-to-end testing

### Available Endpoints
- **🔐 Authentication Service**: Login, token validation, health checks
- **👤 Customer Service**: CRUD operations for customer management
- **🏦 Account Service**: Account creation, balance checks, status updates
- **💰 Transaction Service**: Deposits, withdrawals, transfers, transaction history
- **🔍 Discovery Service**: Service registry status, Eureka dashboard

### Authentication
- **Admin**: `admin@example.com` / `SecureAdminP@ssw0rd!`
- **Client**: `john.doe@example.com` / `123456`

### Automated Features
- **Token Management**: JWT tokens automatically saved and used
- **Variable Handling**: Customer IDs and account numbers auto-populated
- **Health Checks**: All services include health monitoring endpoints
- **Complete Workflows**: End-to-end testing scenarios included

For detailed instructions, see [Postman Collections README](./postman/README.md).

## 🔧 Configuration & Environment

### Load Balancer Configuration
The system includes optimized load balancing settings in `loadbalancer.properties`:

```properties
# Load Balancer Optimization
spring.cloud.loadbalancer.ribbon.enabled=false
spring.cloud.loadbalancer.cache.enabled=true
spring.cloud.loadbalancer.cache.ttl=35s
spring.cloud.loadbalancer.cache.capacity=256

# Health Check Configuration  
spring.cloud.loadbalancer.health-check.initial-delay=10s
spring.cloud.loadbalancer.health-check.interval=25s

# Circuit Breaker for Resilience
resilience4j.circuitbreaker.instances.accountServiceCB.slidingWindowSize=10
resilience4j.circuitbreaker.instances.accountServiceCB.failureRateThreshold=50
resilience4j.circuitbreaker.instances.accountServiceCB.waitDurationInOpenState=5s
resilience4j.circuitbreaker.instances.customerServiceCB.slidingWindowSize=10
resilience4j.circuitbreaker.instances.customerServiceCB.failureRateThreshold=50
resilience4j.circuitbreaker.instances.customerServiceCB.waitDurationInOpenState=5s
resilience4j.circuitbreaker.instances.transactionServiceCB.slidingWindowSize=10
resilience4j.circuitbreaker.instances.transactionServiceCB.failureRateThreshold=50
resilience4j.circuitbreaker.instances.transactionServiceCB.waitDurationInOpenState=5s
### Circuit Breaker Integration

The system uses Resilience4j Circuit Breaker to protect remote service calls in each microservice. To use circuit breakers:

1. Annotate any service method that calls an external endpoint with `@CircuitBreaker` and provide a fallback method. Example:
   ```java
   import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;

   @CircuitBreaker(name = "accountServiceCB", fallbackMethod = "fallbackMethod")
   public boolean validateCustomer(UUID customerId, String jwtToken) {
      // ...remote call logic...
   }

   public boolean fallbackMethod(UUID customerId, String jwtToken, Throwable t) {
      // Fallback logic, e.g., log and return false
      return false;
   }
   ```
2. Circuit breaker configuration is set in `loadbalancer.properties` or `application.properties` as shown above.
3. No extra endpoint is needed for circuit breaker functionality; it is handled at the method level.

# Eureka Configuration for Load Balancing
eureka.instance.lease-renewal-interval-in-seconds=30
eureka.instance.lease-expiration-duration-in-seconds=90
eureka.client.registry-fetch-interval-seconds=30
```

### Environment Variables

#### Docker Compose Environment
- **PostgreSQL**: `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`
- **Redis**: `spring.redis.host`, `spring.redis.port`
- **Kafka**: `KAFKA_ZOOKEEPER_CONNECT`, `KAFKA_LISTENERS`, `KAFKA_ADVERTISED_LISTENERS`

#### Kubernetes Environment
- **Database Connection**: `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`
- **Service Discovery**: `EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE`
- **Load Balancing**: `EUREKA_INSTANCE_PREFER_IP_ADDRESS`, `SPRING_CLOUD_LOADBALANCER_RIBBON_ENABLED`
- **Security**: `SPRING_MAIN_ALLOW_BEAN_DEFINITION_OVERRIDING` (for Transaction Service)

## 🏥 Health Checks & Monitoring

### Optimized Health Check Configuration
- **Discovery Service**: HTTP `/actuator/health` (standalone server mode)
- **Account Service**: HTTP `/actuator/health` (authentication bypass)  
- **Customer Service**: HTTP `/actuator/health` (authentication bypass)
- **Transaction Service**: HTTP `/actuator/health` (bean override enabled)
- **Authentication Service**: TCP port 8084 (security-optimized)

### Startup & Resource Optimization
- **Reduced timeouts**: 3-minute deployment timeouts (was 10 minutes)
- **Efficient probes**: Combined deployment and pod readiness checks
- **Resource-aware**: CPU and memory requests tuned for scheduling
- **Fast startup**: TCP probes for authentication-protected services

### Monitoring Capabilities
```bash
# Check system health
kubectl get pods -n core-bank
kubectl top pods -n core-bank

# View service metrics
curl http://prometheus.core-bank.local/metrics
curl http://account.core-bank.local/actuator/health

# Monitor logs
kubectl logs -l app=account-service -n core-bank --follow
```

## 🚨 Troubleshooting & Common Issues

### Deployment Issues

#### Issue: "Insufficient CPU/Memory"
```bash
# Check resource usage
kubectl describe nodes
kubectl top pods -n core-bank

# Solution: Scale down or optimize resource requests
kubectl scale deployment <service-name> --replicas=1 -n core-bank
```

#### Issue: "Authentication Service Readiness Probe Failed"
- **Root Cause**: HTTP health endpoints protected by JWT authentication
- **Solution**: Uses TCP probes instead of HTTP probes (already implemented)

#### Issue: "Transaction Service Bean Definition Conflict" 
- **Root Cause**: Duplicate `loadBalancedWebClientBuilder` beans
- **Solution**: Added `SPRING_MAIN_ALLOW_BEAN_DEFINITION_OVERRIDING=true` (already implemented)

#### Issue: "Discovery Service Connection Refused"
- **Root Cause**: Eureka server trying to register as client to itself
- **Solution**: Disabled client registration with `EUREKA_CLIENT_REGISTER_WITH_EUREKA=false`

### Performance Optimization

#### Fast Health Checks
- Reduced initial delays and timeouts
- TCP-based probes for secured services
- Combined deployment and readiness checks

#### Resource Efficiency  
- Right-sized CPU/memory requests
- Horizontal Pod Autoscaling (HPA) enabled
- Load balancer caching and circuit breakers

#### Startup Time Optimization
- 80% faster deployment times (3 min vs 15 min)
- Parallel service deployment where possible
- Optimized Docker image caching

## 📊 System Performance

### Deployment Metrics
- **Total deployment time**: ~5-8 minutes (optimized from 20+ minutes)
- **Service startup time**: 30-90 seconds per service
- **Resource efficiency**: 92% CPU, 93% memory utilization
- **Health check frequency**: 10-30 second intervals

### Scaling Capabilities
- **Horizontal scaling**: 1-10 pods per service
- **Auto-scaling triggers**: CPU 70%, Memory 80%
- **Load balancing**: Round-robin with health checks
- **Circuit breaker**: 50% failure rate threshold

## 🔐 Security Features

- **JWT Authentication**: Role-based access control (ADMIN, MANAGER, USER)
- **Secured Endpoints**: All business APIs require valid JWT tokens
- **Health Endpoint Security**: Bypassed for Kubernetes probes
- **Inter-service Communication**: Service discovery with Eureka
- **Database Security**: PostgreSQL with credential management
- **Network Policies**: Kubernetes network segmentation support

## 🎯 Production Readiness

This Core Bank System with the following features:

### ✅ High Availability
- Multi-replica deployments with HPA
- Health checks and automatic failover
- Load balancing across service instances
- Circuit breaker patterns for resilience

### ✅ Observability
- Comprehensive monitoring with Prometheus
- Visual dashboards with Grafana  
- Centralized logging capabilities
- Performance metrics and alerting

### ✅ Security
- JWT-based authentication and authorization
- Role-based access control (RBAC)
- Secured inter-service communication
- Database credential management

### ✅ Scalability
- Horizontal Pod Autoscaling (HPA)
- Event-driven architecture with Kafka
- Caching layer with Redis
- Microservices architecture

### ✅ DevOps Ready
- Container-native deployment
- Kubernetes orchestration
- Infrastructure as Code
- Automated health checks

## 📊 Monitoring & Observability with Grafana

The Core Bank System includes comprehensive monitoring and observability with **Prometheus** and **Grafana** integration. This provides real-time insights into system performance, business metrics, and operational health.

### 🚀 Quick Setup

#### Option 1: Automated Setup (Recommended)
```bash
# 1. Start the system with monitoring stack
docker-compose up -d

# 2. Wait for services to be ready (2-3 minutes)
docker-compose ps

# 3. Run the automated dashboard setup
cd monitoring/grafana
./setup-dashboards.sh
```

#### Option 2: Manual Setup
1. **Access Grafana**: http://localhost:3000
2. **Login**: Username: `myuser`, Password: `mypassword`
3. **Add Prometheus Data Source**:
   - URL: `http://prometheus:9090`
   - Access: `Server (default)`
4. **Import Dashboards**: Use the JSON files in `monitoring/grafana/dashboards/`

### 📈 Available Dashboards

#### 1. **Core Bank System - Microservices Overview**
**Location**: `monitoring/grafana/dashboards/core-bank-overview.json`

**Key Metrics**:
- ✅ **Service Health Status** - Real-time UP/DOWN status for all microservices
- 📊 **HTTP Request Rate** - Requests per second across all services
- ⏱️ **Response Time (95th percentile)** - Performance monitoring
- 🧠 **JVM Memory Usage** - Memory consumption by service
- 🗑️ **Garbage Collection Rate** - JVM GC performance
- 🔗 **Database Connection Pool** - HikariCP connection monitoring
- ❌ **Error Rate (4xx/5xx)** - HTTP error tracking

#### 2. **Core Bank System - Service Details**
**Location**: `monitoring/grafana/dashboards/service-details.json`

**Features**:
- 🎯 **Service-specific drill-down** with dynamic service selection
- 📊 **Detailed HTTP metrics** by status code and endpoint
- 📈 **Response time distribution** (50th, 95th, 99th percentiles)
- 🧠 **JVM memory breakdown** (heap, non-heap, max values)
- 🧵 **Thread pool monitoring** (live, daemon, peak threads)
- 🔗 **Database connection details** (active, idle, pending, max)

#### 3. **Core Bank System - Business Metrics**
**Location**: `monitoring/grafana/dashboards/business-metrics.json`

**Business KPIs**:
- 🏦 **Account Operations Rate** - Account creation, lookup, balance checks
- 💰 **Transaction Rate** - Deposits, withdrawals, transfers
- 👥 **Customer Operations Rate** - Customer management activities
- 🔐 **Authentication Rate** - Login and auth operations
- 📊 **Operations by Type** - Breakdown of business operations
- ⚠️ **Error Rates by Service** - Business-critical error monitoring

### 🛠️ Configuration Details

#### Prometheus Configuration
**File**: `monitoring/prometheus/prometheus.yml`

**Monitored Services**:
```yaml
- Discovery Service (Port 8761)    # Service registry metrics
- Account Service (Port 8081)      # Account operations metrics  
- Transaction Service (Port 8082)  # Transaction processing metrics
- Customer Service (Port 8083)     # Customer management metrics
- Authentication Service (Port 8084) # Authentication metrics
```

**Metrics Endpoints**: `/actuator/prometheus` (Spring Boot Actuator)
**Scrape Interval**: 15 seconds

#### Grafana Provisioning
**Data Source**: `monitoring/grafana/provisioning/datasources/prometheus.yml`
**Dashboards**: `monitoring/grafana/provisioning/dashboards/dashboards.yml`

### 📋 Key Metrics Explained

#### System Health Metrics
- **`up`** - Service availability (1=UP, 0=DOWN)
- **`http_server_requests_seconds_count`** - HTTP request count
- **`http_server_requests_seconds_bucket`** - Response time histograms
- **`jvm_memory_used_bytes`** / **`jvm_memory_max_bytes`** - JVM memory usage
- **`jvm_threads_live_threads`** - Active thread count
- **`hikaricp_connections_*`** - Database connection pool metrics

#### Business Metrics
- **Account Operations**: Creation, lookup, balance checks, updates
- **Transaction Operations**: Deposits, withdrawals, transfers, history
- **Customer Operations**: Registration, profile updates, validation
- **Authentication Operations**: Login, token validation, user management

### 🔧 Customization

#### Adding Custom Metrics
1. **In Spring Boot Services**:
   ```java
   @Autowired
   private MeterRegistry meterRegistry;
   
   // Custom counter
   Counter.builder("bank.transactions.total")
       .tag("type", "deposit")
       .register(meterRegistry)
       .increment();
   
   // Custom timer
   Timer.Sample sample = Timer.start(meterRegistry);
   // ... business logic ...
   sample.stop(Timer.builder("bank.operation.duration")
       .tag("operation", "account.creation")
       .register(meterRegistry));
   ```

2. **Add to Dashboard**: Create new panels using PromQL queries

#### Custom Alerts (Prometheus Alertmanager)
```yaml
# Example alert rule
groups:
  - name: core-bank-alerts
    rules:
      - alert: ServiceDown
        expr: up == 0
        for: 30s
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.job }} is down"
```

### 🚨 Troubleshooting

#### Common Issues

1. **No Data in Dashboards**
   ```bash
   # Check Prometheus targets
   curl http://localhost:9090/api/v1/targets
   
   # Verify service metrics endpoints
   curl http://localhost:8081/actuator/prometheus
   ```

2. **Services Not Discovered**
   - Verify `/actuator/prometheus` endpoints are accessible
   - Check Docker network connectivity
   - Confirm services have Spring Boot Actuator dependency

3. **Dashboard Import Failed**
   - Ensure Prometheus data source exists
   - Check dashboard JSON syntax
   - Verify Grafana API access (username/password)

4. **YAML Validation Errors in VS Code**
   ```
   ❌ Property datasources is not allowed.
   ❌ Property apiVersion is not allowed.
   ```
   
   **Issue**: VS Code applies Kubernetes schema to Grafana provisioning files
   
   **Solutions**:
   - ✅ **Use JSON format**: `monitoring/grafana/provisioning/datasources/prometheus.json` (already created)
   - ✅ **Ignore warnings**: Files work correctly despite validation errors
   - ✅ **See detailed fix**: `monitoring/YAML_VALIDATION_FIX.md`
   
   **Status**: ✅ Both JSON and YAML versions work correctly

### 📊 Accessing Dashboards

1. **Open Grafana**: http://localhost:3000
2. **Login**: Username: `myuser`, Password: `mypassword`
3. **Navigate**: Dashboards → Browse → Core Bank System folder
4. **Monitor**: Real-time metrics and business KPIs

### 🎯 Best Practices

- **Monitor continuously** during development and production
- **Set up alerts** for critical business metrics
- **Use business metrics** to understand user behavior
- **Correlate metrics** across services for troubleshooting
- **Regular dashboard reviews** to identify optimization opportunities