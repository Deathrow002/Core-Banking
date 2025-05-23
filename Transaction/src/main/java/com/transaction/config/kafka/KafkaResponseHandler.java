package com.transaction.config.kafka;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
public class KafkaResponseHandler {
    private static final Logger log = LoggerFactory.getLogger(KafkaResponseHandler.class);

    private final ConcurrentHashMap<String, CompletableFuture<String>> responseMap = new ConcurrentHashMap<>();

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
}
