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
                throw new IllegalArgumentException("Insufficient balance");
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
        } catch (IllegalArgumentException e) {
            log.error("Error processing transaction: {}", e.getMessage());
            throw new IllegalArgumentException("Error processing transaction: " + e.getMessage());
        } catch (Exception e) {
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
        } catch (IllegalArgumentException e) {
            log.error("Error processing deposit transaction: {}", e.getMessage());
            throw new IllegalArgumentException("Error processing deposit transaction: " + e.getMessage());
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
                throw new IllegalArgumentException("Insufficient balance");
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
        } catch (IllegalArgumentException e) {
            log.error("Error processing withdrawal transaction: {}", e.getMessage());
            throw new IllegalArgumentException("Error processing withdrawal transaction: " + e.getMessage());
        } catch (RuntimeException e) {
            log.error("Error processing withdrawal transaction: {}", e.getMessage());
            throw new RuntimeException("Error processing withdrawal transaction: " + e.getMessage());
        }
    }
}
