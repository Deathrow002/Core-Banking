package com.account.service.kafka;

import com.account.model.DTO.AccountDTO;
import com.account.service.AccountService;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;
import java.util.Base64;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class KafkaConsumerService {

    private static final Logger log = LoggerFactory.getLogger(KafkaConsumerService.class);

    @Autowired
    private AccountService accountService;

    @Value("${encryption.secret-key}")
    private String secretKey;

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
            log.info("Successfully processed transaction event for account: {}", accountDTO.getAccNo());
        } catch (Exception e) {
            log.error("Error processing transaction event: {}", e.getMessage(), e);
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
