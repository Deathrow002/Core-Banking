# Build Stage
FROM maven:3.9.9-eclipse-temurin-21 AS builder

WORKDIR /app

# Copy the parent POM and install it
COPY ./pom.xml /app/

# Install all dependencies (including Discovery)
RUN mvn clean install -N

# Copy the entire Discovery module (including pom.xml and src/)
COPY ./Discovery /app/Discovery

# Build the Account service
RUN mvn clean package -DskipTests -f Discovery/pom.xml

# Runtime Stage
FROM eclipse-temurin:21-jre-jammy

# Install wget and curl
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends wget curl && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the built JAR from the builder stage
COPY --from=builder /app/Discovery/target/Discovery-1.0-SNAPSHOT.jar discovery-service.jar

EXPOSE 8761

ENTRYPOINT ["java", "-jar", "discovery-service.jar"]