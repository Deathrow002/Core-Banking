package com.customer.service.kafka;

import java.util.Base64;
import java.util.UUID;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.customer.config.kafka.KafkaResponseHandler;
import com.customer.service.CustomerService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class KafkaConsumerService {
    private static final Logger log = LoggerFactory.getLogger(KafkaConsumerService.class);

    private KafkaProducerService kafkaProducerService;

    private KafkaResponseHandler kafkaResponseHandler;

    private CustomerService customerService;

    @Value("${encryption.secret-key}")
    private String secretKey;

    @KafkaListener(topics = "customer-check", groupId = "account-service-group")
    @Transactional
    public void consumeCustomerCheckEvent(String message, @Header("correlationId") String correlationId) {
        try {
            log.info("Received message from Kafka: {}", message);

            // Decrypt the message (if applicable)
            String decryptedMessage = decrypt(message);
            log.debug("Decrypted message: {}", decryptedMessage);

            // Check if the customer exists
            Boolean customerExists = customerService.existsById(UUID.fromString(decryptedMessage));

            log.info("Customer existence check result: {}", customerExists);

            // Send the result back to Kafka
            kafkaProducerService.sendMessageWithHeaders(
                    "customer-check-response",
                    customerExists.toString(),
                    correlationId
            );
            log.info("Sent response to customer-check-response topic: {}", customerExists);

        } catch (IllegalArgumentException e) {
            log.error("Invalid UUID format: {}", e.getMessage());
            throw new RuntimeException("Invalid UUID format", e);
        } catch (Exception e) {
            log.error("Error processing customer check event: {}", e.getMessage(), e);
            throw new RuntimeException("Error processing customer check event", e);
        }
    }

    @KafkaListener(topics = "account-create-response", groupId = "customer-service-group")
    public void consumeAccountCreateResponse(String message, @Header("correlationId") String correlationId) {
        try {
            log.info("Received response from Kafka: {}", message);

            // Decrypt the message (if applicable)
            String decryptedMessage = decrypt(message); // Ensure this matches the encryption logic in AccountService

            // Notify the waiting thread
            kafkaResponseHandler.complete(correlationId, decryptedMessage);
        } catch (Exception e) {
            log.error("Error processing account create response: {}", e.getMessage(), e);
        }
    }

    private String decrypt(String encryptedMessage) throws Exception {
        SecretKeySpec secretKeySpec = new SecretKeySpec(secretKey.getBytes(), "AES");
        Cipher cipher = Cipher.getInstance("AES");
        cipher.init(Cipher.DECRYPT_MODE, secretKeySpec);
        byte[] decodedBytes = Base64.getDecoder().decode(encryptedMessage);
        byte[] decryptedBytes = cipher.doFinal(decodedBytes);
        return new String(decryptedBytes);
    }

}
