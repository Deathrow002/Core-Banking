# Use an official OpenJDK runtime as a parent image
FROM openjdk:21-jdk-slim

LABEL authors="krittamettanboontor"

# Set working directory
WORKDIR /app

# Copy built JAR files for each service
COPY Account/target/Account-1.0-SNAPSHOT.jar /app/account-service.jar
COPY Transaction/target/Transaction-1.0-SNAPSHOT.jar /app/transaction-service.jar
COPY Discovery/target/Discovery-1.0-SNAPSHOT.jar /app/discovery-service.jar

# Expose ports based on the service
ARG PORT
EXPOSE ${PORT}

# Entry point based on the provided command
ENTRYPOINT ["java", "-jar"]