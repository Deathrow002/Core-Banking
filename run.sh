#!/bin/bash

# Define a usage function
usage() {
  echo "Usage: $0 {account|transaction|discovery}"
  exit 1
}

# Check for the provided argument
if [ $# -eq 0 ]; then
  usage
fi

SERVICE=$1

# Start the selected service
case $SERVICE in
  account)
    echo "Starting Account Service..."
    java -jar /app/Account.jar
    ;;
  transaction)
    echo "Starting Transaction Service..."
    java -jar /app/Transaction.jar
    ;;
  discovery)
    echo "Starting Discovery Service..."
    java -jar /app/Discovery.jar
    ;;
  *)
    usage
    ;;
esac
