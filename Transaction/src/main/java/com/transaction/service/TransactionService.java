package com.transaction.service;

import java.util.List;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.transaction.model.DTO.AccountPayload;
import com.transaction.model.Transaction;
import com.transaction.repository.TransactionRepository;
import com.transaction.service.kafka.KafkaProducerService;

import lombok.RequiredArgsConstructor;
import reactor.core.publisher.Mono;

@Service
@EnableCaching
@RequiredArgsConstructor
public class TransactionService {
    private static final Logger log = LoggerFactory.getLogger(TransactionService.class);
    private final TransactionRepository transactionRepository;
    private final WebClient.Builder webClientBuilder;
    private final KafkaProducerService kafkaProducerService;

    String checkAccountUrl  = "http://ACCOUNT-SERVICE/accounts/validateAccount";
    String checkBalanceUrl  = "http://ACCOUNT-SERVICE/accounts/getAccount";

    public Mono<Transaction> transaction(Transaction transaction){
        return transactionRepository.save(transaction);
    }

    public Mono<List<Transaction>> getAllTransactionByAccount(UUID AccNo){
        return transactionRepository.findAllByAccNoOwner(AccNo).collectList();
    }

    public Mono<Boolean> isAccountValid(UUID accountNumber, String jwtToken) {
        String requestUrl = checkAccountUrl + "?accNo=" + accountNumber;
        return webClientBuilder.build().get()
                .uri(requestUrl)
                .header("Authorization", "Bearer " + jwtToken)
                .retrieve()
                .bodyToMono(Boolean.class)
                .doOnNext(valid -> log.info("Account {} valid: {}", accountNumber, valid))
                .onErrorResume(e -> {
                    log.warn("Error validating account {}: {}", accountNumber, e.getMessage());
                    return Mono.just(false);
                });
    }

    public Mono<AccountPayload> getAccountDetail(UUID accountNumber, String jwtToken) {
        String requestUrl = checkBalanceUrl + "?accNo=" + accountNumber;
        return webClientBuilder.build().get()
                .uri(requestUrl)
                .header("Authorization", "Bearer " + jwtToken)
                .retrieve()
                .bodyToMono(AccountPayload.class)
                .doOnNext(payload -> log.info("Successfully retrieved account details for {}: {}", accountNumber, payload))
                .onErrorResume(e -> {
                    log.warn("Error retrieving account details for {}: {}", accountNumber, e.getMessage());
                    return Mono.empty();
                });
    }

    public Mono<Void> updateAccountBalance(String topic, AccountPayload accountPayload) {
        ObjectMapper objectMapper = new ObjectMapper();
        String jsonPayload;
        try {
            jsonPayload = objectMapper.writeValueAsString(accountPayload);
        } catch (JsonProcessingException e) {
            log.error("Failed to serialize AccountPayload for account: {}", accountPayload.getAccountId(), e);
            return Mono.error(e);
        }
        // If your Kafka producer is reactive, return its Mono. Otherwise, wrap in Mono.fromRunnable:
        return Mono.fromRunnable(() -> {
            kafkaProducerService.sendMessage(topic, jsonPayload);
            log.info("Successfully sent account balance update for account: {}", accountPayload.getAccountId());
        });
    }
}
