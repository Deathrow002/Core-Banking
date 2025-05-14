package com.transaction.service;

import java.util.UUID;

import org.springframework.stereotype.Component;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.transaction.model.DTO.AccountPayload;
import com.transaction.model.DTO.TransactionDTO;

import lombok.RequiredArgsConstructor;


@RequiredArgsConstructor
@Component
@Service
public class TransactionProcess {
    private final TransactionService transactionService;

    String checkAccountUrl  = "http://ACCOUNT-SERVICE/accounts/validateAccount";
    String checkBalanceUrl  = "http://ACCOUNT-SERVICE/accounts/getAccount";


    // Helper method to validate an account
    private boolean isValidAccount(UUID accountNumber) {
        return !transactionService.isAccountValid(checkAccountUrl, accountNumber);
    }

    // Method to process transactions between Owner and Receiver
    @Transactional
    public TransactionDTO transactionProcess(TransactionDTO transactionDTO) {
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

        return transactionDTO;
    }

    // Method to process deposit transactions
    @Transactional
    public TransactionDTO depositProcess(TransactionDTO transactionDTO) {
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

        // Add balance to Owner's account
        ownerPayload.setBalance(ownerPayload.getBalance().add(transactionDTO.getAmount()));

        return transactionDTO;
    }

    // Method to process withdrawal transactions
    @Transactional
    public TransactionDTO withdrawProcess(TransactionDTO transactionDTO) {
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

        // Deduct balance from Owner's account
        ownerPayload.setBalance(ownerPayload.getBalance().subtract(transactionDTO.getAmount()));

        return transactionDTO;
    }
}
