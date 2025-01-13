# Use an official OpenJDK runtime as a parent image
FROM openjdk:21-jdk-slim

LABEL authors="krittamettanboontor"

# Set working directory
WORKDIR /app

# Install git
RUN apt-get update && apt-get install -y git maven

# Clone the repository
RUN git clone https://github.com/Deathrow002/Core-Banking.git

# Build the project
WORKDIR /app/Core-Banking/Discovery
RUN mvn clean package

# Expose port
EXPOSE 8761

# Entry point
ENTRYPOINT ["java", "-jar", "/app/discovery-service.jar"]