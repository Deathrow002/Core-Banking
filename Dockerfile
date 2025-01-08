# Use an official OpenJDK runtime as a parent image
FROM openjdk:17-jdk-slim AS build

LABEL authors="krittamettanboontor"

# Set working directory
WORKDIR /app

# Install git and maven to clone the repository and build the application
RUN apt-get update && \
    apt-get install -y git maven && \
    rm -rf /var/lib/apt/lists/*

# Clone the repository
RUN git clone https://github.com/Deathrow002/Core-Banking.git .

# Build the application (assumes Maven is used)
RUN mvn clean package -DskipTests

# Final image for running the app
FROM openjdk:17-jdk-slim

# Set working directory
WORKDIR /app

# Copy the built JAR file from the build stage
COPY --from=build /app/target/core-bank-1.0-SNAPSHOT.jar /app/core-bank.jar

# Expose the port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "/app/core-bank.jar"]
