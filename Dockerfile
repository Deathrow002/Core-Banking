# Use an official OpenJDK runtime as a parent image
FROM openjdk:21-jdk-slim AS build

LABEL authors="krittamettanboontor"

# Set working directory
WORKDIR /app

# Install git and maven to clone the repository and build the application
RUN apt-get update && \
    apt-get install -y git maven && \
    rm -rf /var/lib/apt/lists/*

# Clone the repository (or copy it from your local system in production)
RUN git clone https://github.com/Deathrow002/Core-Banking.git .

# Build the application (assumes Maven is used)
RUN mvn clean package -DskipTests

# Final image for running the app
FROM openjdk:21-jdk-slim

# Set working directory
WORKDIR /app

# Copy the built JAR files from the build stage
COPY --from=build /app/Account/target/*.jar /app/Account.jar
COPY --from=build /app/Transaction/target/*.jar /app/Transaction.jar
COPY --from=build /app/Discovery/target/*.jar /app/Discovery.jar

# Copy the run script
COPY run.sh /app/run.sh
RUN chmod +x /app/run.sh

# Expose the port (assuming your app runs on 8080)
EXPOSE 8080

# Run the application using the script
ENTRYPOINT ["/app/run.sh"]
