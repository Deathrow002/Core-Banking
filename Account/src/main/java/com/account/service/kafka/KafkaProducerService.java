package com.account.service.kafka;

import java.util.Base64;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.stereotype.Service;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class KafkaProducerService {

    private static final Logger log = LoggerFactory.getLogger(KafkaProducerService.class);

    private final KafkaTemplate<String, String> kafkaTemplate;

    @Value("${encryption.secret-key}")
    private String secretKey;

    // Send a message to the specified Kafka topic
    public void sendMessage(String topic, String message) {
        try {
            log.info("Preparing to send message to topic {}: {}", topic, message);

            // Encrypt the message
            String encryptedMessage = encrypt(message);
            log.debug("Encrypted message: {}", encryptedMessage);

            // Send the encrypted message to Kafka
            kafkaTemplate.send(topic, encryptedMessage).whenComplete((result, ex) -> {
                if (ex == null) {
                    log.info("Message successfully sent to topic {} with offset {}", topic, result.getRecordMetadata().offset());
                } else {
                    log.error("Failed to send message to topic {}: {}", topic, ex.getMessage());
                }
            });
        } catch (Exception e) {
            log.error("Error encrypting and sending message: {}", e.getMessage(), e);
        }
    }

    // Send a message to the specified Kafka topic with headers
    public void sendMessageWithHeaders(String topic, String message, String correlationId) {
        try {
            log.info("Preparing to send message to topic {}: {}", topic, message);

            // Encrypt the message (if applicable)
            String encryptedMessage = encrypt(message);

            // Build the message with headers
            kafkaTemplate.send(
                MessageBuilder.withPayload(encryptedMessage) // Ensure this is plain text if encryption is not needed
                    .setHeader(KafkaHeaders.TOPIC, topic)
                    .setHeader("correlationId", correlationId)
                    .build()
            ).whenComplete((result, ex) -> {
                if (ex == null) {
                    log.info("Message successfully sent to topic {} with offset {}", topic, result.getRecordMetadata().offset());
                } else {
                    log.error("Failed to send message to topic {}: {}", topic, ex.getMessage());
                }
            });
        } catch (Exception e) {
            log.error("Error encrypting and sending message: {}", e.getMessage(), e);
        }
    }

    // Encrypt the message using AES encryption
    private String encrypt(String message) throws Exception {
        SecretKeySpec secretKeySpec = new SecretKeySpec(secretKey.getBytes(), "AES");
        Cipher cipher = Cipher.getInstance("AES");
        cipher.init(Cipher.ENCRYPT_MODE, secretKeySpec);
        byte[] encryptedBytes = cipher.doFinal(message.getBytes());
        return Base64.getEncoder().encodeToString(encryptedBytes);
    }
}
