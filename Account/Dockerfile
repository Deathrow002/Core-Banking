# Build Stage
FROM maven:3.9.9-eclipse-temurin-21-alpine AS builder

WORKDIR /app

# Copy the parent POM and install it
COPY ./pom.xml /app/

# Install all dependencies (including Account)
RUN mvn clean install -N

# Copy the entire Account module (including pom.xml and src/)
COPY ./Account /app/Account

# Build the Account service
RUN mvn clean package -DskipTests -f Account/pom.xml

# Runtime Stage
FROM eclipse-temurin:21-jre-jammy

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y wget curl && apt-get clean

WORKDIR /app

# Copy the built JAR from the builder stage
COPY --from=builder /app/Account/target/Account-1.0-SNAPSHOT.jar account-service.jar

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "account-service.jar"]