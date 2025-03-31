package com.account.service;

import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

@Service
public class KafkaConsumerService {

    @KafkaListener(topics = "transaction-events", groupId = "account-service-group")
    public void consumeTransactionEvent(String message) {
        System.out.println("Received transaction event: " + message);
        // Process the message (e.g., update account balances)
    }
}
