# Build stage
FROM maven:3.9.4-eclipse-temurin-21 AS builder

LABEL authors="krittamettanboontor"

WORKDIR /app

# Copy local source code to the container
COPY . .

# Pass repository URL and branch as arguments
#ARG REPO_URL=https://github.com/Deathrow002/Core-Banking.git
#ARG BRANCH=master

# Clone the repository and debug
#RUN git clone --branch ${BRANCH} ${REPO_URL} .

# Build the project (skip tests for faster build)
RUN mvn clean package -DskipTests -X

# Check if JAR is created and verify the structure
RUN ls -l /app/Discovery/target

# Runtime stage
FROM openjdk:21-jdk-slim

LABEL authors="Krittamet Tanboontor"

WORKDIR /app

# Install curl for debugging & health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy the built JAR from the build stage
COPY --from=builder /app/Discovery/target/Discovery-1.0-SNAPSHOT.jar /app/discovery-service.jar

EXPOSE 8761

ENTRYPOINT ["java", "-jar", "discovery-service.jar"]