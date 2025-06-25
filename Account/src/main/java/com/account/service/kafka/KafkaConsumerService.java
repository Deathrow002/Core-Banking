package com.account.service.kafka;

import java.util.Base64;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;

import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.stereotype.Service;

import com.account.config.kafka.JwtKafkaMessageConverter;
import com.account.config.kafka.JwtKafkaMessageConverter.JwtInfo;
import com.account.config.kafka.KafkaResponseHandler;
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
    
    private final JwtKafkaMessageConverter jwtMessageConverter;

    @Value("${encryption.secret-key}")
    private String secretKey;

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

    // This method listens for account balance update events
    // It uses the @KafkaListener annotation to listen to the "account-balance-update" topic
    // and the "account-service-group" consumer group
    // It also uses the JwtKafkaMessageConverter to extract and validate JWT information from Kafka headers
    // It decrypts the message, deserializes it into an AccountDTO object,
    // and processes the account balance update with security context
    // It also performs authorization checks to ensure the user has a valid role
    @KafkaListener(topics = "account-balance-update", groupId = "account-service-group")
    public void consumeAccountBalanceUpdate(ConsumerRecord<String, String> record) {
        try {
            String message = record.value();
            log.info("Received account balance update from Kafka: {}", message);

            // Extract and validate JWT information from Kafka headers
            JwtInfo jwtInfo = jwtMessageConverter.extractJwtInfo(record.headers());
            log.info("JWT Info: {}", jwtInfo);
            
            if (!jwtInfo.isValid()) {
                log.error("Invalid or missing JWT token in account balance update message: {}", jwtInfo.getError());
                // You can choose to either throw an exception or handle gracefully
                // For now, we'll log the error but continue processing
                log.warn("Processing account balance update without valid JWT authentication");
            } else {
                log.info("Successfully authenticated request from user: {} with role: {} for customer: {}", 
                        jwtInfo.getUsername(), jwtInfo.getRole(), jwtInfo.getCustomerId());
            }

            // Decrypt the message
            String decryptedMessage = decrypt(message);
            log.debug("Decrypted message: {}", decryptedMessage);

            // Deserialize the JSON string directly to AccountDTO
            ObjectMapper objectMapper = new ObjectMapper();
            AccountDTO accountDTO = objectMapper.readValue(decryptedMessage, AccountDTO.class);
            
            log.info("Mapped AccountDTO: {}", accountDTO);

            // Authorization check: verify user has valid role (ADMIN, MANAGER, or USER)
            if (jwtInfo.isValid()) {
                String userRole = jwtInfo.getRole();
                boolean hasValidRole = userRole != null && 
                    (userRole.contains("ADMIN") || userRole.contains("MANAGER") || userRole.contains("USER"));
                
                if (!hasValidRole) {
                    log.error("Authorization failed: User {} with role {} does not have permission to update account balances", 
                             jwtInfo.getUsername(), userRole);
                    throw new SecurityException("Insufficient permissions - user does not have required role");
                }
                
                log.info("Authorization successful: User {} with role {} is authorized to update account {}", 
                        jwtInfo.getUsername(), userRole, accountDTO.getAccountId());
            } else {
                log.error("Authorization failed: Invalid or missing JWT token");
                throw new SecurityException("Invalid authentication - JWT token required");
            }

            // Process the account balance update with security context
            accountService.updateAccountBalance(accountDTO);
            log.info("Successfully processed account balance update for account: {} by user: {}", 
                    accountDTO.getAccountId(), jwtInfo.isValid() ? jwtInfo.getUsername() : "unauthenticated");
        } catch (Exception e) {
            log.error("Error processing account balance update: {}", e.getMessage(), e);
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
