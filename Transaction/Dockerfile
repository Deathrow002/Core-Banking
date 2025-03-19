# Build stage
FROM maven:3.9.4-eclipse-temurin-21 as builder

LABEL authors="krittamettanboontor"

WORKDIR /app

# Copy local source code to the container
#COPY . .

# Pass repository URL and branch as arguments
ARG REPO_URL=https://github.com/Deathrow002/Core-Banking.git
ARG BRANCH=master

# Clone the repository and debug
RUN git clone --branch ${BRANCH} ${REPO_URL} .

# Now build Discovery service
RUN mvn clean package -DskipTests -X

# Runtime stage
FROM openjdk:21-jdk-slim

RUN apt update ; DEBIAN_FRONTEND=noninteractive apt install -y wget ; apk add --no-cache curl

WORKDIR /app

COPY --from=builder /app/Transaction/target/Transaction-1.0-SNAPSHOT.jar transaction-service.jar
#COPY target/Transaction-1.0-SNAPSHOT.jar transaction-service.jar

EXPOSE 8082

ENTRYPOINT ["java", "-jar", "transaction-service.jar"]
