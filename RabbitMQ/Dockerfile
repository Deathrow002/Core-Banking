FROM rabbitmq:3.12-management

# Set environment variables for RabbitMQ
ENV RABBITMQ_DEFAULT_USER=user
ENV RABBITMQ_DEFAULT_PASS=password

# Expose the necessary ports
EXPOSE 5672 15672

# Command to run RabbitMQ server
CMD ["rabbitmq-server"]