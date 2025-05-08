package com.customer.service.kafka;

import java.util.Base64;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
public class KafkaProducerService {
    private static final Logger log = LoggerFactory.getLogger(KafkaProducerService.class);

    @Autowired
    private KafkaTemplate<String, byte[]> kafkaTemplate;

    @Value("${encryption.secret-key}")
    private String secretKey;

    public void sendMessage(String topic, byte[] message) {
        try {
            log.info("Sending message to topic {}: {}", topic, new String(message));

            // Encrypt the message
            String encryptedMessage = encrypt(new String(message));
            log.debug("Encrypted message: {}", encryptedMessage);

            // Send the encrypted message to Kafka
            kafkaTemplate.send(topic, encryptedMessage.getBytes());
            log.info("Message successfully sent to topic {}", topic);
        } catch (Exception e) {
            log.error("Error encrypting and sending message: {}", e.getMessage(), e);
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
