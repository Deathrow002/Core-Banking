# Build stage
FROM maven:3.9.4-eclipse-temurin-21 as builder

LABEL authors="krittamettanboontor"

WORKDIR /app

# Pass repository URL and branch as arguments
ARG REPO_URL=https://github.com/Deathrow002/Core-Banking.git
ARG BRANCH=master

# Clone the repository and debug
RUN git clone --branch ${BRANCH} ${REPO_URL} .
RUN mvn clean package -DskipTests

# Runtime stage
FROM openjdk:21-jdk-slim
WORKDIR /app
COPY --from=builder /app/Transaction/target/Transaction-1.0-SNAPSHOT.jar transaction-service.jar
EXPOSE 8082
ENTRYPOINT ["java", "-jar", "transaction-service.jar"]
