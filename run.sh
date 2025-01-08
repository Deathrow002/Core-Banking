#!/bin/bash

# Start Account service
nohup java -jar /app/Account.jar &

# Start Transaction service
nohup java -jar /app/Transaction.jar &

# Start Discovery service
nohup java -jar /app/Discovery.jar &

# Wait indefinitely (or you could include something else to keep the container running)
wait
