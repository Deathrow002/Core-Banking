package com.transaction.service;

import java.util.List;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.transaction.model.DTO.AccountPayload;
import com.transaction.model.Transaction;
import com.transaction.repository.TransactionRepository;
import com.transaction.service.kafka.KafkaProducerService;

import lombok.RequiredArgsConstructor;

@Service
@EnableCaching
@RequiredArgsConstructor
public class TransactionService {
    private static final Logger log = LoggerFactory.getLogger(TransactionService.class);
    private final TransactionRepository transactionRepository;
    private final RestTemplate restTemplate;
    private final KafkaProducerService kafkaProducerService;

    public Transaction transaction(Transaction transaction){
        return transactionRepository.save(transaction);
    }

    public List<Transaction> getAllTransactionByAccount(UUID AccNo){
        return transactionRepository.getAllTransactionByAccount(AccNo);
    }

    public boolean isAccountValid(String url, UUID accountNumber, String jwtToken) {
        String requestUrl = url + "?accNo=" + accountNumber;

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + jwtToken);
        HttpEntity<Void> entity = new HttpEntity<>(headers);

        ResponseEntity<Boolean> response = restTemplate.exchange(
            requestUrl,
            HttpMethod.GET,
            entity,
            Boolean.class
        );

        if (response.getStatusCode().is2xxSuccessful()) {
            Boolean isValid = response.getBody();
            return Boolean.TRUE.equals(isValid);
        } else {
            log.warn("Non-success HTTP response: {} for account {} from URL: {}",
                    response.getStatusCode(), accountNumber, requestUrl);
            throw new RestClientException("Unsuccessful response from account validation service");
        }
    }

    public AccountPayload getAccountDetail(String url, UUID accountNumber, String jwtToken) {
        String requestUrl = url + "?accNo=" + accountNumber;

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + jwtToken);
        HttpEntity<Void> entity = new HttpEntity<>(headers);

        // Log raw response as a string for debugging
        ResponseEntity<String> rawResponse = restTemplate.exchange(
            requestUrl,
            HttpMethod.GET,
            entity,
            String.class
        );
        log.info("Raw Response: {}", rawResponse.getBody());

        if ("true".equalsIgnoreCase(rawResponse.getBody()) || "false".equalsIgnoreCase(rawResponse.getBody())) {
            log.warn("Received a boolean response instead of account details for account: {}", accountNumber);
            throw new RestClientException("Received a boolean response instead of account details");
        }

        ResponseEntity<AccountPayload> responsePayload = restTemplate.exchange(
            requestUrl,
            HttpMethod.GET,
            entity,
            AccountPayload.class
        );

        if (responsePayload.getStatusCode().is2xxSuccessful() && responsePayload.getBody() != null) {
            AccountPayload accountPayload = responsePayload.getBody();
            log.info("Successfully retrieved account details for {}: {}", accountNumber, accountPayload);
            return accountPayload;
        } else {
            log.warn("Unsuccessful response for account: {}, Status Code: {}", accountNumber, responsePayload.getStatusCode());
            throw new RestClientException("Unsuccessful response for account: " + accountNumber);
        }
    }

    public Boolean updateAccountBalance(String topic, AccountPayload accountPayload) {
        // Serialize the AccountPayload as a JSON string
        ObjectMapper objectMapper = new ObjectMapper();
        String jsonPayload;
        try {
            jsonPayload = objectMapper.writeValueAsString(accountPayload);
        } catch (JsonProcessingException e) {
            log.error("Failed to serialize AccountPayload for account: {}", accountPayload.getAccountId(), e);
            return false;
        }

        // Send the serialized message to Kafka
        kafkaProducerService.sendMessage(topic, jsonPayload);
        log.info("Successfully sent account balance update for account: {}", accountPayload.getAccountId());
        return true;
    }
}
