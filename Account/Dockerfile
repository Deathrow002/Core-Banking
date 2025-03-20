## Build stage
#FROM maven:3.9.4-eclipse-temurin-21 as builder
#
#LABEL authors="krittamettanboontor"
#
#WORKDIR /app
#
## Copy the pom.xml and download dependencies
#COPY pom.xml .
#RUN mvn dependency:go-offline -B
#
## Copy the entire source code into the container
#COPY src /app/src
#
## Build the service (Discovery, Account, or any other)
#RUN mvn clean package -DskipTests -X

# Runtime stage
FROM openjdk:21-jdk-slim

LABEL authors="krittamettanboontor"

# Install necessary runtime dependencies (if needed)
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y wget curl redis-tools && \
    apt-get clean

WORKDIR /app

# Copy the JAR file from the builder stage into the runtime image
#COPY --from=builder /app/Account/target/Account-1.0-SNAPSHOT.jar account-service.jar
COPY target/Account-1.0-SNAPSHOT.jar account-service.jar

# Expose the port for the service
EXPOSE 8081

# Run the service with the given JAR file
ENTRYPOINT ["java", "-jar", "account-service.jar"]
