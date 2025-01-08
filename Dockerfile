FROM ubuntu:latest
LABEL authors="krittamettanboontor"

# Use an official OpenJDK runtime as a parent image
FROM openjdk:17-jdk-slim

# Set working directory
WORKDIR /app

# Install git to clone the repository
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Clone the repository
RUN git clone https://github.com/Deathrow002/Core-Banking.git .

# Build the application (assumes Maven is used)
RUN apt-get update && apt-get install -y maven && rm -rf /var/lib/apt/lists/*
RUN mvn clean package -DskipTests

# Expose the port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "target/your-application.jar"]
