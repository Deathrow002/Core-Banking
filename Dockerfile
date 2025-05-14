# Use an official OpenJDK runtime as a parent image
FROM eclipse-temurin:21-jdk-jammy

# Ensure all packages are up to date to minimize vulnerabilities
RUN apt-get update && apt-get upgrade -y && apt-get clean && rm -rf /var/lib/apt/lists/*

LABEL authors="krittamettanboontor"

# Set working directory
WORKDIR /app

# Clone the repository and debug
RUN mvn clean package -DskipTests

# Copy built JAR files for each service
COPY Account/target/Account-1.0-SNAPSHOT.jar /app/account-service.jar
COPY Transaction/target/Transaction-1.0-SNAPSHOT.jar /app/transaction-service.jar
COPY Discovery/target/Discovery-1.0-SNAPSHOT.jar /app/discovery-service.jar

# Install curl (if you need it for health checks or debugging)
RUN apt-get update && apt-get install -y curl

# Expose ports based on the service, you can define PORT as a build argument
ARG PORT
EXPOSE ${PORT}

# Entry point based on the provided command
ENTRYPOINT ["java", "-jar"]