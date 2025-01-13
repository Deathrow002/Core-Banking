# Use an official OpenJDK runtime as a parent image
FROM openjdk:21-jdk-slim AS builder

LABEL authors="krittamettanboontor"

# Set working directory
WORKDIR /app

# Install required tools
RUN apt-get update && apt-get install -y --no-install-recommends git maven \
    && rm -rf /var/lib/apt/lists/*

# Pass repository URL and branch as arguments
ARG REPO_URL=https://github.com/Deathrow002/Core-Banking.git
ARG BRANCH=main

# Clone the repository and build the application
RUN git clone --branch ${BRANCH} ${REPO_URL} . \
    && mvn clean package -DskipTests

# Use a minimal base image for the final build
FROM openjdk:21-jdk-slim

# Set working directory
WORKDIR /app

# Copy the built artifact from the builder stage
COPY --from=builder /app/target/*.jar app.jar

# Expose port
EXPOSE 8081

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]