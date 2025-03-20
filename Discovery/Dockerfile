## Build stage
#FROM maven:3.9.4-eclipse-temurin-21 AS builder
#
#LABEL authors="krittamettanboontor"
#
#WORKDIR /app
#
## Copy local source code to the container
##COPY . .
#
## Pass repository URL and branch as arguments
#ARG REPO_URL=https://github.com/Deathrow002/Core-Banking.git
#ARG BRANCH=master
#
## Clone the repository and debug
#RUN git clone --branch ${BRANCH} ${REPO_URL} . && \
#    cd /app && \
#    git fetch origin && \
#    git checkout ${BRANCH} && \
#    git pull origin ${BRANCH}
#
## Now build Discovery service
#RUN mvn clean package -DskipTests -X
#
## Check if JAR is created and verify the structure
#RUN ls -l /app/Discovery/target

# Stage 2: Build the actual JAR file (using the resolved dependencies)
FROM openjdk:21-jdk-slim

LABEL authors="krittamettanboontor"

WORKDIR /app

# Runtime stage: Run the application
FROM openjdk:21-jdk-slim

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y wget curl && apt-get clean

WORKDIR /app

# Copy the built JAR from the builder stage
#COPY --from=builder /app/Discovery/target/Discovery-1.0-SNAPSHOT.jar discovery-service.jar
COPY target/Discovery-1.0-SNAPSHOT.jar discovery-service.jar
