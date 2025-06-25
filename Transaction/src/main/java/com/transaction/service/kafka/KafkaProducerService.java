package com.transaction.service.kafka;

import java.util.Base64;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;

import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.header.Header;
import org.apache.kafka.common.header.internals.RecordHeader;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import lombok.RequiredArgsConstructor;
import reactor.core.publisher.Mono;

@Service
@RequiredArgsConstructor
public class KafkaProducerService {

    private static final Logger log = LoggerFactory.getLogger(KafkaProducerService.class);

    private final KafkaTemplate<String, String> kafkaTemplate;

    @Value("${encryption.secret-key}")
    private String secretKey;

    public void sendMessage(String topic, String message) {
        try {
            log.info("Sending message to topic {}: {}", topic, message);

            // Encrypt the message
            String encryptedMessage = encrypt(message);
            log.debug("Encrypted message: {}", encryptedMessage);

            // Send the encrypted message to Kafka
            kafkaTemplate.send(topic, encryptedMessage)
                .thenAccept(result -> log.info("Message successfully sent to topic {} with offset {}", 
                    topic, result.getRecordMetadata().offset()))
                .exceptionally(ex -> {
                    log.error("Failed to send message to topic {}: {}", topic, ex.getMessage());
                    return null;
                });
        } catch (Exception e) {
            log.error("Error encrypting and sending message: {}", e.getMessage(), e);
        }
    }

    public Mono<Void> sendMessageReactive(String topic, String message, String jwtToken) {
        try {
            String encrypted = encrypt(message);

            // Create ProducerRecord with header
            ProducerRecord<String, String> record = new ProducerRecord<>(topic, encrypted);
            Header authHeader = new RecordHeader("Authorization", jwtToken.getBytes());
            record.headers().add(authHeader);

            return Mono.create(sink ->
                kafkaTemplate.send(record)
                    .thenAccept(result -> sink.success())
                    .exceptionally(ex -> { sink.error(ex); return null; })
            );
        } catch (Exception e) {
            return Mono.error(new RuntimeException("Encryption failed", e));
        }
    }

    private String encrypt(String message) throws Exception {
        SecretKeySpec secretKeySpec = new SecretKeySpec(secretKey.getBytes(), "AES");
        Cipher cipher = Cipher.getInstance("AES");
        cipher.init(Cipher.ENCRYPT_MODE, secretKeySpec);
        byte[] encryptedBytes = cipher.doFinal(message.getBytes());
        return Base64.getEncoder().encodeToString(encryptedBytes);
    }
}
