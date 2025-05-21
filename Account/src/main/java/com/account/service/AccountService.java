package com.account.service;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import org.jetbrains.annotations.NotNull;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.account.config.KafkaResponseHandler;
import com.account.model.Account;
import com.account.model.DTO.AccountDTO;
import com.account.repository.AccountRepository;
import com.account.service.kafka.KafkaProducerService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class AccountService {
    private static final Logger log = LoggerFactory.getLogger(AccountService.class);

    private final AccountRepository accountRepository;

    private final KafkaProducerService kafkaProducerService;

    private final KafkaResponseHandler kafkaResponseHandler;

    //Check Account Balance
    public Optional<Account> checkBalance(UUID AccNo){
        return accountRepository.findById(AccNo);
    }

    //Create First Account
    @Transactional
    // This method creates the first account for a customer
    public void createFirstAccount(@NotNull AccountDTO accountDTO) {
        try {
            log.debug("Starting first account creation for customer ID: {}", accountDTO.getCustomerId());

            // Validate input
            if (accountDTO.getCustomerId() == null) {
                throw new IllegalArgumentException("Customer ID is null");
            }

            // Create and save the account
            Account account = new Account(
                accountDTO.getCustomerId(),
                accountDTO.getBalance(),
                accountDTO.getCurrency()
            );

            // Save the account
            log.debug("Saving first account for customer ID: {}", accountDTO.getCustomerId());
            accountRepository.save(account);

            // Log success
            log.info("First account successfully created for customer ID: {}", accountDTO.getCustomerId());
        } catch (RuntimeException e) {
            log.error("Error during first account creation: {}", e.getMessage(), e);
            throw new RuntimeException("First account creation failed", e);
        }
    }

    //Create Account
    @Transactional
    public Account createAccount(@NotNull AccountDTO accountDTO) {
        try {
            log.debug("Starting account creation for customer ID: {}", accountDTO.getCustomerId());

            // Validate input
            if (accountDTO.getCustomerId() == null) {
                throw new IllegalArgumentException("Customer ID is null");
            }

            // Generate a unique correlation ID
            String correlationId = UUID.randomUUID().toString();
            log.debug("Generated correlation ID: {}", correlationId);
            log.debug("Waiting for response with correlation ID: {}", correlationId);

            // Send a message to Kafka to check if the customer exists
            CompletableFuture<String> responseFuture = new CompletableFuture<>();

            // Register the response handler with the correlation ID
            kafkaResponseHandler.register(correlationId, responseFuture);

            // Send the message to Kafka
            kafkaProducerService.sendMessageWithHeaders(
                "customer-check",
                accountDTO.getCustomerId().toString(),
                correlationId
            ); 

            // Wait for the response with a timeout
            String response = responseFuture.get(30, TimeUnit.SECONDS);
            log.info("Received response from Kafka: {}", response);

            // Create and save the account
            Account account = new Account(
                accountDTO.getCustomerId(),
                accountDTO.getBalance(),
                accountDTO.getCurrency()
            );

            // Check if the customer exists
            if (Boolean.parseBoolean(response)) {
                log.error("Customer with ID {} does not exist", accountDTO.getCustomerId());
                throw new RuntimeException("Customer does not exist");
            }

            // Save the account
            log.debug("Saving account for customer ID: {}", accountDTO.getCustomerId());
            Account savedAccount = accountRepository.save(account);

            // Log success
            log.info("Account successfully created for customer ID: {}", accountDTO.getCustomerId());
            return savedAccount;
        } catch (ExecutionException | InterruptedException | TimeoutException | RuntimeException e) {
            log.error("Error during account creation: {}", e.getMessage(), e);
            throw new RuntimeException("Account creation failed", e);
        }
    }

    //Update Account Balance
    public Account updateAccountBalance(@NotNull AccountDTO accountDTO){
        //Prepare Payload
        Account payload = accountRepository.findById(UUID.fromString(accountDTO.getAccountId().toString())).get();

        //Set New Balance to Payload
        payload.setBalance(accountDTO.getBalance());

        //Update Balance
        return accountRepository.save(payload);
    }

    //Delete Account
    public void deleteAccount(UUID AccNo){
        accountRepository.deleteById(AccNo);
    }

    //Get All Accounts
    public List<Account> getAllAccounts(){
        return accountRepository.findAll();
    }

    //Get Account by Customer ID
    public List<Account> searchByCustomerId(UUID customerId){
        return accountRepository.findByCustomerId(customerId);
    }

    //Check if Account Exists
    public boolean existsById(UUID AccNo) {
        return accountRepository.existsById(AccNo);
    }
}
