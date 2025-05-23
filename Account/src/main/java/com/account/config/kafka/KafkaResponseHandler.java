package com.account.config.kafka;

import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Component;

import com.account.service.kafka.KafkaProducerService;

import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
public class KafkaResponseHandler {

    private static final Logger log = LoggerFactory.getLogger(KafkaResponseHandler.class);

    private final ConcurrentHashMap<String, CompletableFuture<String>> responseMap = new ConcurrentHashMap<>();

    @Lazy
    private final KafkaProducerService kafkaProducerService;

    // This method is called to register a CompletableFuture with a correlation ID
    // This allows us to wait for a response associated with that ID
    public void register(String correlationId, CompletableFuture<String> future) {
        log.debug("Registering future for correlation ID: {}", correlationId);
        responseMap.put(correlationId, future);
    }

    // This method is called when a response is received
    public void complete(String correlationId, String response) {
        CompletableFuture<String> future = responseMap.remove(correlationId);
        if (future != null) {
            future.complete(response);
        }
    }

    public String sendAndWaitForResponse(String topic, String message) throws Exception {
        String correlationId = UUID.randomUUID().toString();
        CompletableFuture<String> future = new CompletableFuture<>();

        // Register the future with the correlation ID
        register(correlationId, future);

        // Send the message to Kafka with the correlation ID
        kafkaProducerService.sendMessageWithHeaders(topic, message, correlationId);

        try {
            // Wait for the response (timeout after 10 seconds)
            return future.get(20, TimeUnit.SECONDS);
        } catch (InterruptedException | ExecutionException | TimeoutException e) {
            log.error("Timeout or error while waiting for response for correlation ID {}: {}", correlationId, e.getMessage());
            throw new RuntimeException("Failed to get response from Kafka", e);
        } finally {
            // Clean up the future from the map in case of timeout or error
            responseMap.remove(correlationId);
        }
    }

    public boolean requestCustomerCheck(UUID customerId) {
        try {
            String response = sendAndWaitForResponse("customer-check", customerId.toString());
            return Boolean.parseBoolean(response);
        } catch (Exception e) {
            log.error("Error checking customer existence: {}", e.getMessage(), e);
            return false;
        }
    }
}
