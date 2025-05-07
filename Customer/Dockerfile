# Build Stage
FROM maven:3.9.4-eclipse-temurin-21 AS builder

WORKDIR /app

# Copy the parent POM and install it
COPY ./pom.xml /app/

# Install all dependencies (including Customer)
RUN mvn clean install -N

# Copy the entire Customer module (including pom.xml and src/)
COPY ./Customer /app/Customer

# Build the Customer service
RUN mvn clean package -DskipTests -f Customer/pom.xml

# Runtime Stage
FROM openjdk:21-jdk-slim

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y wget curl && apt-get clean

WORKDIR /app

# Copy the built JAR from the builder stage
COPY --from=builder /app/Customer/target/Customer-1.0-SNAPSHOT.jar customer-service.jar

EXPOSE 8083

ENTRYPOINT ["java", "-jar", "customer-service.jar"]