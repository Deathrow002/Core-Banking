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
## Pass repository URL and branch as arguments
##ARG REPO_URL=https://github.com/Deathrow002/Core-Banking.git
##ARG BRANCH=master
#
## Clone the repository and debug
##RUN git clone --branch ${BRANCH} ${REPO_URL} . && \
##    cd /app && \
##    git fetch origin && \
##    git checkout ${BRANCH} && \
##    git pull origin ${BRANCH}
#
## Now build Discovery service
#RUN mvn clean package -DskipTests -X

# Runtime stage
FROM openjdk:21-jdk-slim

LABEL authors="krittamettanboontor"

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y wget curl redis-tools && \
    apt-get clean

WORKDIR /app

#COPY --from=builder /app/Transaction/target/Transaction-1.0-SNAPSHOT.jar transaction-service.jar
COPY target/Transaction-1.0-SNAPSHOT.jar transaction-service.jar

EXPOSE 8082

ENTRYPOINT ["java", "-jar", "transaction-service.jar"]
