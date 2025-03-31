package com.transaction.service.kafka;

import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

@Service
public class KafkaConsumerService {

    @KafkaListener(topics = "account-events", groupId = "transaction-service-group")
    public void consumeMessage(String message) {
        System.out.println("Received message: " + message);
        // Process the message
    }
}
