package com.transaction.service;

import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.transaction.model.DTO.AccountPayload;
import com.transaction.model.DTO.TransactionDTO;
import com.transaction.model.TransacType;
import com.transaction.model.Transaction;
import com.transaction.repository.TransactionRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class TransactionProcess {
    private final TransactionService transactionService;
    private final TransactionRepository transactionRepository;
    // private final TransactionReactiveRepository transactionReactiveRepository;
    private static final Logger log = LoggerFactory.getLogger(TransactionProcess.class);

    String checkAccountUrl  = "http://ACCOUNT-SERVICE/accounts/validateAccount";
    String checkBalanceUrl  = "http://ACCOUNT-SERVICE/accounts/getAccount";


    // Helper method to validate an account
    private boolean isValidAccount(UUID accountNumber) {
        return !transactionService.isAccountValid(checkAccountUrl, accountNumber);
    }

    // Method to process transactions between Owner and Receiver
    @Transactional
    public Transaction transactionProcess(TransactionDTO transactionDTO) {
        try{
            // Validate both Owner and Receiver's account in a single function
            if (isValidAccount(transactionDTO.getAccNoOwner()) || isValidAccount(transactionDTO.getAccNoReceive())) {
                throw new IllegalArgumentException("Invalid account details");
            }

            // Retrieve account details for Owner and Receiver
            AccountPayload ownerPayload = transactionService.getAccountDetail(checkBalanceUrl, transactionDTO.getAccNoOwner());
            AccountPayload receiverPayload = transactionService.getAccountDetail(checkBalanceUrl, transactionDTO.getAccNoReceive());

            // Check if account details are valid
            if (ownerPayload == null || receiverPayload == null) {
                throw new IllegalArgumentException("Invalid account details");
            }

            // Check if Owner has sufficient balance
            if (ownerPayload.getBalance().compareTo(transactionDTO.getAmount()) < 0) {
                throw new IllegalArgumentException("Insufficient funds");
            }

            // Deduct balance from Owner and add it to Receiver
            ownerPayload.setBalance(ownerPayload.getBalance().subtract(transactionDTO.getAmount()));
            receiverPayload.setBalance(receiverPayload.getBalance().add(transactionDTO.getAmount()));

            // Save the transaction
            Transaction response = transactionRepository.save(new Transaction(
                    transactionDTO.getAccNoOwner(),
                    transactionDTO.getAccNoReceive(),
                    transactionDTO.getAmount(),
                    TransacType.Transaction
            ));

            // Send Update Account balances to Kafka
            transactionService.updateAccountBalance("account-balance-update", ownerPayload);
            transactionService.updateAccountBalance("account-balance-update", receiverPayload);
            log.info("Transaction processed successfully: Owner {} to Receiver {}", transactionDTO.getAccNoOwner(), transactionDTO.getAccNoReceive());
            log.info("Transaction amount: {}", transactionDTO.getAmount());

            return response;
        } catch (RuntimeException e) {
            log.error("Error processing transaction: {}", e.getMessage());
            throw new RuntimeException("Error processing transaction: " + e.getMessage());
        }
    }

    // Method to process deposit transactions
    @Transactional
    public Transaction depositProcess(TransactionDTO transactionDTO) {
        try {
            // Validate Owner's account
            if (isValidAccount(transactionDTO.getAccNoOwner())) {
                throw new IllegalArgumentException("Invalid account details");  
            }

            // Retrieve account details for Owner
            AccountPayload ownerPayload = transactionService.getAccountDetail(checkBalanceUrl, transactionDTO.getAccNoOwner());

            // Check if account details are valid
            if (ownerPayload == null) {
                throw new IllegalArgumentException("Invalid account details");
            }

            // Deduct balance from Owner
            ownerPayload.setBalance(ownerPayload.getBalance().add(transactionDTO.getAmount()));

            // Save the transaction
            Transaction response = transactionRepository.save(new Transaction(
                    transactionDTO.getAccNoOwner(),
                    transactionDTO.getAmount(),
                    TransacType.Deposit
            ));

            // Update Owner's balance
            transactionService.updateAccountBalance("account-balance-update", ownerPayload);
            log.info("Deposit processed successfully for account: {}", transactionDTO.getAccNoOwner());
            log.info("Deposit amount: {}", transactionDTO.getAmount());

            return response;
        } catch (RuntimeException e) {
            log.error("Error processing deposit transaction: {}", e.getMessage());
            throw new RuntimeException("Error processing deposit transaction: " + e.getMessage());
        }
    }

    // Method to process withdrawal transactions
    @Transactional
    public Transaction withdrawProcess(TransactionDTO transactionDTO) {
        try {
            // Validate Owner's account
            if (isValidAccount(transactionDTO.getAccNoOwner())) {
                throw new IllegalArgumentException("Invalid account details");
            }

            // Retrieve account details for Owner
            AccountPayload ownerPayload = transactionService.getAccountDetail(checkBalanceUrl, transactionDTO.getAccNoOwner());

            // Check if account details are valid
            if (ownerPayload == null) {
                throw new IllegalArgumentException("Invalid account details");
            }

            // Check if Owner has sufficient balance
            if (ownerPayload.getBalance().compareTo(transactionDTO.getAmount()) < 0) {
                throw new IllegalArgumentException("Insufficient funds");
            }

            // Deduct balance from Owner
            ownerPayload.setBalance(ownerPayload.getBalance().subtract(transactionDTO.getAmount()));

            // Save the transaction
            Transaction response = transactionRepository.save(new Transaction(
                    transactionDTO.getAccNoOwner(),
                    transactionDTO.getAmount(),
                    TransacType.Withdraw
            ));

            // Update Owner's balance
            transactionService.updateAccountBalance("account-balance-update", ownerPayload);
            log.info("Withdrawal processed successfully for account: {}", transactionDTO.getAccNoOwner());
            log.info("Withdrawal amount: {}", transactionDTO.getAmount());

            return response;
        } catch (RuntimeException e) {
            log.error("Error processing withdrawal transaction: {}", e.getMessage());
            throw new RuntimeException("Error processing withdrawal transaction: " + e.getMessage());
        }
    }

    // public Mono<Transaction> transactionProcessReactive(TransactionDTO transactionDTO) {
    //     // Validate both Owner and Receiver's account reactively
    //     Mono<Boolean> ownerValid = transactionService.isAccountValidReactive(checkAccountUrl, transactionDTO.getAccNoOwner());
    //     Mono<Boolean> receiverValid = transactionService.isAccountValidReactive(checkAccountUrl, transactionDTO.getAccNoReceive());

    //     return Mono.zip(ownerValid, receiverValid)
    //         .flatMap(validTuple -> { 
    //             // Check if either account is invalid
    //             if (validTuple.getT1() || validTuple.getT2()) {
    //                 return Mono.error(new IllegalArgumentException("Invalid account details"));
    //             }

    //             // Retrieve account details for Owner and Receiver reactively
    //             Mono<AccountPayload> ownerPayloadMono = transactionService.getAccountDetailReactive(checkBalanceUrl, transactionDTO.getAccNoOwner());
    //             Mono<AccountPayload> receiverPayloadMono = transactionService.getAccountDetailReactive(checkBalanceUrl, transactionDTO.getAccNoReceive());
                
    //             return Mono.zip(ownerPayloadMono, receiverPayloadMono);

    //         }).flatMap(payloadTuple -> {
    //             AccountPayload ownerPayload = payloadTuple.getT1();
    //             AccountPayload receiverPayload = payloadTuple.getT2();

    //             if (ownerPayload == null || receiverPayload == null) {
    //                 return Mono.error(new IllegalArgumentException("Invalid account details"));
    //             }
    //             if (ownerPayload.getBalance().compareTo(transactionDTO.getAmount()) < 0) {
    //                 return Mono.error(new IllegalArgumentException("Insufficient funds"));
    //             }

    //             ownerPayload.setBalance(ownerPayload.getBalance().subtract(transactionDTO.getAmount()));
    //             receiverPayload.setBalance(receiverPayload.getBalance().add(transactionDTO.getAmount()));

    //             Transaction transaction = new Transaction(
    //                 transactionDTO.getAccNoOwner(),
    //                 transactionDTO.getAccNoReceive(),
    //                 transactionDTO.getAmount(),
    //                 TransacType.Transaction
    //             );

    //             Mono<Transaction> savedTransactionMono = transactionReactiveRepository.save(transaction);

    //             return savedTransactionMono
    //                 .flatMap(savedTx -> 
    //                     Mono.when(
    //                         transactionService.updateAccountBalanceReactive("account-balance-update", ownerPayload),
    //                         transactionService.updateAccountBalanceReactive("account-balance-update", receiverPayload)
    //                     ).then(Mono.just(savedTx))
    //                 );
    //         })
    //         .doOnSuccess(response -> log.info("Reactive transaction processed successfully: Owner {} to Receiver {}, Amount: {}", transactionDTO.getAccNoOwner(), transactionDTO.getAccNoReceive(), transactionDTO.getAmount()))
    //         .doOnError(e -> log.error("Error processing reactive transaction: {}", e.getMessage(), e));
    // }
}
