# Build Stage
FROM maven:3.9.6-eclipse-temurin-21-noble

ARG AS builder

WORKDIR /app

# Copy the parent POM and install it
COPY ./pom.xml /app/

# Install all dependencies (including Account)
RUN mvn clean install -N

# Copy the entire Transaction module (including pom.xml and src/)
COPY ./Transaction /app/Transaction

# Build the Transaction service (after Account is installed)
RUN mvn clean package -DskipTests -f Transaction/pom.xml

# Runtime Stage
FROM eclipse-temurin:21-jre-jammy

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends wget curl && \
	apt-get upgrade -y && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the built JAR from the builder stage
COPY --from=builder /app/Transaction/target/Transaction-1.0-SNAPSHOT.jar transaction-service.jar

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "transaction-service.jar"]
