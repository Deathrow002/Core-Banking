package com.transaction.service;

import java.math.BigInteger;
import java.util.List;

import com.transaction.model.DTO.AccountPayload;
import com.transaction.service.kafka.KafkaProducerService;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.transaction.model.Transaction;
import com.transaction.repository.TransactionRepository;

import com.fasterxml.jackson.databind.ObjectMapper;

@Service
@EnableCaching
public class TransactionService {
    private static final Logger log = LoggerFactory.getLogger(TransactionService.class);
    @Autowired
    private TransactionRepository transactionRepository;

    private final KafkaProducerService kafkaProducerService;
    private final RestTemplate restTemplate;

    public TransactionService(KafkaProducerService kafkaProducerService, RestTemplate restTemplate) {
        this.kafkaProducerService = kafkaProducerService;
        this.restTemplate = restTemplate;
    }

    public Transaction transaction(Transaction transaction){
        return transactionRepository.save(transaction);
    }

    public List<Transaction> getAllTransactionByAccount(Long AccNo){
        return transactionRepository.getAllTransactionByAccount(AccNo);
    }

    public boolean isAccountValid(String url, BigInteger accountNumber) {
        try {
            // Prepare the request body
            String requestUrl = url + "?accNo=" + accountNumber;

            // Make the request
            ResponseEntity<Boolean> response = restTemplate.getForEntity(requestUrl, Boolean.class);

            // Check response status and body
            if (response.getStatusCode().is2xxSuccessful()) {
                Boolean isValid = response.getBody();
                return Boolean.TRUE.equals(isValid);
            } else {
                log.warn("Non-success HTTP response: {} for account {} from URL: {}",
                        response.getStatusCode(), accountNumber, requestUrl);
                return false;
            }
        } catch (HttpClientErrorException e) {
            log.error("Client error while verifying account {}: {}", accountNumber, e.getMessage());
            return false;
        } catch (ResourceAccessException e) {
            log.error("Resource access error for URL {}: {}", url, e.getMessage());
            return false;
        } catch (RestClientException e) {
            log.error("Unexpected error while verifying account {}: {}", accountNumber, e.getMessage());
            return false;
        }
    }

    public AccountPayload getAccountDetail(String url, BigInteger accountNumber) {
        try {
            // Prepare the request URL
            String requestUrl = url + "?accNo=" + accountNumber;

            // Log raw response as a string for debugging
            ResponseEntity<String> rawResponse = restTemplate.getForEntity(requestUrl, String.class);
            log.info("Raw Response: {}", rawResponse.getBody());

            // Check if the response is a boolean
            if ("true".equalsIgnoreCase(rawResponse.getBody()) || "false".equalsIgnoreCase(rawResponse.getBody())) {
                log.warn("Received a boolean response instead of account details for account: {}", accountNumber);
                return null;
            }

            // Parse response directly to AccountPayload
            ResponseEntity<AccountPayload> responsePayload = restTemplate.getForEntity(requestUrl, AccountPayload.class);

            // Validate the response
            if (responsePayload.getStatusCode().is2xxSuccessful() && responsePayload.getBody() != null) {
                AccountPayload accountPayload = responsePayload.getBody();
                log.info("Successfully retrieved account details for {}: {}", accountNumber, accountPayload);
                return accountPayload;
            } else {
                log.warn("Unsuccessful response for account: {}, Status Code: {}", accountNumber, responsePayload.getStatusCode());
            }
        } catch (HttpClientErrorException e) {
            log.error("Client error while verifying account {}: {}", accountNumber, e.getMessage());
        } catch (ResourceAccessException e) {
            log.error("Resource access error for URL {}: {}", url, e.getMessage());
        } catch (RestClientException e) {
            log.error("Unexpected error while validating account {}: {}", accountNumber, e.getMessage());
        }

        return null;
    }

    public Boolean updateAccountBalance(String topic, AccountPayload accountPayload) {
        try {
            // Serialize the AccountPayload as a JSON string
            ObjectMapper objectMapper = new ObjectMapper();
            String jsonPayload = objectMapper.writeValueAsString(accountPayload);

            // Send the serialized message to Kafka
            kafkaProducerService.sendMessage(topic, jsonPayload.getBytes());
            log.info("Successfully sent account balance update for account: {}", accountPayload.getAccountId());
            return true;
        } catch (JsonProcessingException e) {
            log.error("Error while sending account balance update for account {}: {}", accountPayload.getAccountId(), e.getMessage());
            return false;
        }
    }
}
