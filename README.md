# Core Bank System

This project is a microservices-based core banking system. It includes multiple services such as account management, transaction processing, customer management, and service discovery, along with supporting infrastructure like PostgreSQL, Redis, Kafka, Prometheus, and Grafana.

## Services Overview

### Core Services
- **Discovery Service**: Service registry using Eureka.
- **Account Service**: Manages user accounts and integrates with PostgreSQL and Redis.
- **Transaction Service**: Handles transactions and integrates with PostgreSQL and Kafka.
- **Customer Service**: Manages customer data, including CRUD operations for customer profiles and addresses.

### Supporting Infrastructure
- **PostgreSQL**: Database for storing account, transaction, and customer data.
- **Redis**: In-memory data store for caching.
- **Kafka**: Message broker for asynchronous communication.
- **Zookeeper**: Manages Kafka cluster.
- **Prometheus**: Monitoring and alerting toolkit.
- **Grafana**: Visualization and analytics platform.

## How It Works

The Core Bank System operates as a collection of microservices that communicate with each other to provide core banking functionalities:

1. **Discovery Service**:
   - Acts as a service registry using Eureka.
   - All services register themselves with the Discovery Service to enable dynamic service discovery.

2. **Account Service**:
   - Manages user accounts, including account creation, updates, and retrieval.
   - Uses PostgreSQL for persistent storage and Redis for caching frequently accessed data.

3. **Transaction Service**:
   - Processes financial transactions such as deposits, withdrawals, and transfers.
   - Publishes transaction events to Kafka for asynchronous processing and auditing.

4. **Customer Service**:
   - Manages customer profiles, including personal details and associated addresses.
   - Supports CRUD operations for customers and their addresses.
   - Uses PostgreSQL for persistent storage.

5. **Supporting Infrastructure**:
   - **PostgreSQL**: Stores account, transaction, and customer data persistently.
   - **Redis**: Provides caching to improve performance.
   - **Kafka**: Facilitates asynchronous communication between services.
   - **Prometheus and Grafana**: Monitor system health and provide visual analytics.

6. **Workflow**:
   - A client sends a request to the Account, Transaction, or Customer Service.
   - The service processes the request, interacts with the database or cache as needed, and optionally publishes events to Kafka.
   - Other services consume Kafka events to perform additional tasks, such as generating reports or updating analytics.

## Prerequisites

- Docker
- Docker Compose

## Setup Instructions

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd core-bank
   ```

2. Start the services using Docker Compose:
   ```bash
   docker-compose up -d
   ```

3. Verify that all services are running:
   - PostgreSQL: `localhost:5432`
   - Redis: `localhost:6379`
   - Kafka: `localhost:9092`
   - Discovery Service: `http://localhost:8761`
   - Account Service: `http://localhost:8081`
   - Transaction Service: `http://localhost:8082`
   - Customer Service: `http://localhost:8080`
   - Prometheus: `http://localhost:9090`
   - Grafana: `http://localhost:3000`

4. Access Grafana and configure Prometheus as a data source:
   - Default Grafana credentials: `admin/admin`

## Postman Collection

To simplify testing and interacting with the Core Bank System, a Postman collection is provided. Follow these steps to use it:

1. Download the Postman collection file: [Core Bank Postman Collection](./postman/CoreBank.postman_collection.json)
2. Import the collection into Postman:
   - Open Postman.
   - Click on "Import" in the top-left corner.
   - Select the downloaded `.json` file.
3. Use the pre-configured requests to test the services:
   - Account Service endpoints.
   - Transaction Service endpoints.
   - Customer Service endpoints.
   - Health check endpoints.

## Environment Variables

The following environment variables are used in the `docker-compose.yml` file:

- **PostgreSQL**:
  - `POSTGRES_DB`: Database name
  - `POSTGRES_USER`: Database username
  - `POSTGRES_PASSWORD`: Database password

- **Redis**:
  - `spring.redis.host`: Redis hostname
  - `spring.redis.port`: Redis port

- **Kafka**:
  - `KAFKA_ZOOKEEPER_CONNECT`: Zookeeper connection string
  - `KAFKA_LISTENERS`: Kafka listeners
  - `KAFKA_ADVERTISED_LISTENERS`: Kafka advertised listeners

## Health Checks

Each service includes health checks to ensure proper startup and operation:
- PostgreSQL: `pg_isready`
- Redis: `redis-cli ping`
- Discovery Service: `/actuator/health`
- Account Service: `/actuator/health`
- Transaction Service: `/actuator/health`
- Customer Service: `/actuator/health`
- Kafka: `kafka-broker-api-versions`

## Volumes

Persistent data is stored in Docker volumes:
- `postgres_data_volume`: PostgreSQL data
- `redis_data_volume`: Redis data
- `grafana_data_volume`: Grafana data

## Troubleshooting

- Use `docker-compose logs <service-name>` to view logs for a specific service.
- Ensure all dependencies are healthy before starting dependent services.

## License

This project is licensed under the MIT License.
