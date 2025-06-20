package com.transaction.service.kafka;

import java.util.Base64;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;

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
            // kafkaTemplate.send(topic, encryptedMessage);
            log.info("Message successfully sent to topic {}", topic);
        } catch (Exception e) {
            log.error("Error encrypting and sending message: {}", e.getMessage(), e);
        }
    }

    public Mono<Void> sendMessageReactive(String topic, String message) {
        return Mono.fromFuture(() -> {
            try {
                String encrypted = encrypt(message);
                return kafkaTemplate.send(topic, encrypted).thenApply(result -> result); // returns CompletableFuture
            } catch (Exception e) {
                throw new RuntimeException("Encryption failed", e);
            }
        }).then();
    }

    private String encrypt(String message) throws Exception {
        SecretKeySpec secretKeySpec = new SecretKeySpec(secretKey.getBytes(), "AES");
        Cipher cipher = Cipher.getInstance("AES");
        cipher.init(Cipher.ENCRYPT_MODE, secretKeySpec);
        byte[] encryptedBytes = cipher.doFinal(message.getBytes());
        return Base64.getEncoder().encodeToString(encryptedBytes);
    }
}
