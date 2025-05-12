package com.customer.config;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Component;

@Component
public class KafkaResponseHandler {

    private final ConcurrentHashMap<String, CompletableFuture<String>> responseMap = new ConcurrentHashMap<>();

    /** 
    // Register a CompletableFuture for a given correlation ID
    // This allows us to wait for a response associated with that ID
    // and complete it when the response is received.
    */
    public void register(String correlationId, CompletableFuture<String> future) {
        responseMap.put(correlationId, future);
    }

    /**
    Complete the CompletableFuture associated with the given correlation ID
    This method is called when a response is received from Kafka.
    It removes the future from the map and completes it with the response.
    This ensures that the caller waiting on the future is notified with the response.
    If the correlation ID is not found, it means the response was not expected,
    and we do not complete any future.
    */
    public void complete(String correlationId, String response) {
        CompletableFuture<String> future = responseMap.remove(correlationId);
        if (future != null) {
            future.complete(response);
        }
    }
}
