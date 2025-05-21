package com.account.service.kafka;

import java.util.Base64;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.stereotype.Service;

import com.account.config.KafkaResponseHandler;
import com.account.model.DTO.AccountDTO;
import com.account.service.AccountService;
import com.fasterxml.jackson.databind.ObjectMapper;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class KafkaConsumerService {

    private static final Logger log = LoggerFactory.getLogger(KafkaConsumerService.class);

    private final AccountService accountService;

    private final KafkaResponseHandler kafkaResponseHandler;

    private final KafkaProducerService kafkaProducerService;

    @Value("${encryption.secret-key}")
    private String secretKey;

    // This method listens for transaction events
    // and processes account balance updates
    // It uses the @KafkaListener annotation to listen to the "account-updates" topic
    // and the "account-service-group" consumer group
    @KafkaListener(topics = "account-updates", groupId = "account-service-group")
    public void consumeTransactionEvent(String message) {
        try {
            log.info("Received message from Kafka: {}", message);

            // Decrypt the message
            String decryptedMessage = decrypt(message);
            log.debug("Decrypted message: {}", decryptedMessage);

            // Deserialize the JSON string into an AccountDTO object
            ObjectMapper objectMapper = new ObjectMapper();
            AccountDTO accountDTO = objectMapper.readValue(decryptedMessage, AccountDTO.class);

            // Process the account balance update
            accountService.updateAccountBalance(accountDTO);
            log.info("Successfully processed transaction event for account: {}", accountDTO.getAccountId());
        } catch (Exception e) {
            log.error("Error processing transaction event: {}", e.getMessage(), e);
        }
    }

    // This method listens for customer create events
    // and processes account creation
    // It uses the @KafkaListener annotation to listen to the "account-create" topic
    // and the "account-service-group" consumer group
    // It also uses the @Header annotation to extract the correlationId from the message headers
    // and sends a response back to the "account-create-response" topic
    // with the correlationId
    // and a success message
    // It uses the @Value annotation to inject the secret key for decryption
    // and the @Autowired annotation to inject the AccountService and KafkaProducerService beans
    // It also uses the @Autowired annotation to inject the KafkaResponseHandler bean
    // and the @KafkaListener annotation to listen to the "account-create" topic
    // and the "account-service-group" consumer group
    // It also uses the @KafkaListener annotation to listen to the "account-create-response" topic
    // and the "account-service-group" consumer group
    // and the @Header annotation to extract the correlationId from the message headers
    // and sends a response back to the "account-create-response" topic
    // with the correlationId
    // and a success message
    @KafkaListener(topics = "account-create", groupId = "account-service-group")
    public void consumeCutomerEvent(String message, @Header("correlationId") String correlationId) {
        try {
            log.info("Received message from Kafka: {}", message);

            // Decrypt the message
            String decryptedMessage = decrypt(message);
            log.debug("Decrypted message: {}", decryptedMessage);

            // Deserialize the JSON string into an AccountDTO object
            ObjectMapper objectMapper = new ObjectMapper();
            AccountDTO accountDTO = objectMapper.readValue(decryptedMessage, AccountDTO.class);

            // Validate the AccountDTO
            if (accountDTO.getCustomerId() == null) {
                throw new IllegalArgumentException("Customer ID is null in the AccountDTO");
            }

            // Process the account creation
            accountService.createFirstAccount(accountDTO);

            // Send a success response back to Kafka
            kafkaProducerService.sendMessageWithHeaders(
                "account-create-response",
                "success",
                correlationId
            );
            log.info("Sent success response to account-create-response topic for correlation ID: {}", correlationId);
        } catch (Exception e) {
            log.error("Error processing customer event for create first account: {}", e.getMessage(), e);
        }
    }

    // This method listens for customer check events
    // and processes account balance checks
    // It uses the @KafkaListener annotation to listen to the "customer-check" topic
    // and the "account-service-group" consumer group
    // It also uses the @Value annotation to inject the secret key for decryption
    // and the @Autowired annotation to inject the AccountService bean
    @KafkaListener(topics = "customer-check", groupId = "account-service-group")
    public void consumeCustomerCheckEvent(String message, @Header("correlationId") String correlationId) {
        try {
            log.info("Received message from Kafka: {}", message);

            // Decrypt the message
            String decryptedMessage = decrypt(message);
            log.debug("Decrypted message: {}", decryptedMessage);

            // Deserialize the JSON string into an AccountDTO object
            ObjectMapper objectMapper = new ObjectMapper();
            AccountDTO accountDTO = objectMapper.readValue(decryptedMessage, AccountDTO.class);

            // Process the account balance update
            accountService.checkBalance(accountDTO.getAccountId());
            log.info("Successfully processed customer check event for account: {}", accountDTO.getAccountId());
        } catch (Exception e) {
            log.error("Error processing customer check event: {}", e.getMessage(), e);
        }
    }

    // This method listens for customer check response events
    // It uses the @KafkaListener annotation to listen to the "customer-check-response" topic
    // and the "account-service-group" consumer group
    @KafkaListener(topics = "customer-check-response", groupId = "account-service-group")
    public void consumeCustomerCheckResponse(String message, @Header("correlationId") String correlationId) {
        try {
            log.info("Received 'customer-check-response' message from Kafka: {}", message);

            // Decrypt the message
            String decryptedMessage = decrypt(message);
            Boolean customerExists = Boolean.valueOf(decryptedMessage);
            log.info("Decrypted message: {}", customerExists);

            // Check if the customer exists
            if (!customerExists) {
                log.error("Customer does not exist for correlation ID: {}", correlationId);
                throw new RuntimeException("Customer does not exist");
            }
            log.info("Customer exists is '{}' for correlation ID: {}", customerExists, correlationId);

            // Notify the waiting thread
            kafkaResponseHandler.complete(correlationId, message);
        } catch (Exception e) {
            log.error("Error processing customer check response: {}", e.getMessage(), e);
        }
    }

    // This method listens for responses from the account creation process
    // It uses the @KafkaListener annotation to listen to the "account-create-response" topic
    // and the "account-service-group" consumer group
    // It also uses the @Header annotation to extract the correlationId from the message headers
    // and notifies the waiting thread using the KafkaResponseHandler
    @KafkaListener(topics = "account-create-response", groupId = "account-service-group")
    public void consumeAccountCreateResponse(String message, @Header("correlationId") String correlationId) {
        try {
            log.info("Received response from Kafka: {}", message);

            // Notify the waiting thread
            kafkaResponseHandler.complete(correlationId, message);
        } catch (Exception e) {
            log.error("Error processing account create response: {}", e.getMessage(), e);
        }
    }

    // Decrypt the message using AES decryption
    // It uses the javax.crypto.Cipher class to perform the decryption
    // and the javax.crypto.spec.SecretKeySpec class to create the secret key
    // It also uses the java.util.Base64 class to decode the encrypted message
    // and the java.lang.String class to convert the decrypted bytes to a string
    private String decrypt(String encryptedMessage) throws Exception {
        SecretKeySpec secretKeySpec = new SecretKeySpec(secretKey.getBytes(), "AES");
        Cipher cipher = Cipher.getInstance("AES");
        cipher.init(Cipher.DECRYPT_MODE, secretKeySpec);
        byte[] decodedBytes = Base64.getDecoder().decode(encryptedMessage);
        byte[] decryptedBytes = cipher.doFinal(decodedBytes);
        return new String(decryptedBytes);
    }
}
