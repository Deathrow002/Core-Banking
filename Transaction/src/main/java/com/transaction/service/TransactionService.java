package com.transaction.service;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.transaction.model.DTO.AccountPayload;
import com.transaction.model.DTO.TransactionDTO;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

import com.transaction.model.Transaction;
import com.transaction.repository.TransactionRepository;

@Service
@EnableCaching
public class TransactionService {
    private static final Logger log = LoggerFactory.getLogger(TransactionService.class);
    @Autowired
    private TransactionRepository transactionRepository;

    private final RestTemplate restTemplate;

    @Autowired
    public TransactionService(RestTemplate restTemplate) {
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
                return isValid;
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
        } catch (Exception e) {
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
        } catch (Exception e) {
            log.error("Unexpected error while validating account {}: {}", accountNumber, e);
        }

        return null;
    }

    public Boolean updateAccountBalance(String url, AccountPayload accountPayload) {
        try {
            // Construct the request URL (the account number is now part of the request body)
            String requestUrl = String.format("%s", url); // Assuming the URL does not require query parameters for account number

            // Prepare the payload (using the AccountDTO as the body)
            Map<String, Object> payload = new HashMap<>();
            payload.put("accNo", accountPayload.getAccNo());
            payload.put("idcNo", accountPayload.getIdcNo());
            payload.put("name", accountPayload.getName());
            payload.put("balance", accountPayload.getBalance());

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(payload, headers);

            // Send the PUT request
            ResponseEntity<Void> response = restTemplate.exchange(
                    requestUrl,
                    HttpMethod.PUT,
                    requestEntity,
                    Void.class
            );

            // Validate the response
            if (response.getStatusCode().is2xxSuccessful()) {
                log.info("Successfully updated account balance for account: {}", accountPayload.getAccNo());
                return true;
            } else {
                log.warn("Failed to update account balance for account: {}, Status Code: {}, Response Body: {}", accountPayload.getAccNo(), response.getStatusCode(), response.getBody());
                return false;
            }
        } catch (HttpClientErrorException e) {
            log.error("Client error while updating account balance for account {}: {}, Response Body: {}", accountPayload.getAccNo(), e.getMessage(), e.getResponseBodyAsString());
        } catch (ResourceAccessException e) {
            log.error("Resource access error for URL {}: {}", url, e.getMessage());
        } catch (Exception e) {
            log.error("Unexpected error while updating account balance for account {}: {}", accountPayload.getAccNo(), e);
        }

        return false;
    }


}
