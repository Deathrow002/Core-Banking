# Build Stage
FROM maven:3.9.9-eclipse-temurin-21-alpine AS builder

WORKDIR /app

# Copy the parent POM and install it
COPY ./pom.xml /app/

# Install all dependencies (including Authentication)
RUN mvn clean install -N

# Copy the entire Authentication module (including pom.xml and src/)
COPY ./Authentication /app/Authentication

# Build the Authentication service
RUN mvn clean package -DskipTests -f Authentication/pom.xml

# Runtime Stage
FROM eclipse-temurin:21-jre-jammy

# Install wget and curl
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends wget curl && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the built JAR from the builder stage
COPY --from=builder /app/Authentication/target/Authentication-1.0-SNAPSHOT.jar authentication-service.jar

EXPOSE 8084

ENTRYPOINT ["java", "-jar", "authentication-service.jar"]