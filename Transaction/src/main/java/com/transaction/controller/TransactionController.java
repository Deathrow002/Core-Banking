package com.transaction.controller;

import com.transaction.model.DTO.AccountPayload;
import com.transaction.model.DTO.TransactionDTO;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.transaction.model.TransacType;
import com.transaction.model.Transaction;
import com.transaction.service.TransactionService;

import java.math.BigInteger;

@RestController
@RequestMapping("/transactions")
@CrossOrigin(origins = "http://localhost:8082")
public class TransactionController {

    @Autowired
    private TransactionService transactionService;

    String checkAccountUrl  = "http://ACCOUNT-SERVICE/accounts/validateAccount";
    String checkBalanceUrl  = "http://ACCOUNT-SERVICE/accounts/getAccount";

    private boolean isValidAccount(BigInteger accountNumber) {
        return transactionService.isAccountValid(checkAccountUrl, accountNumber);
    }

    @PostMapping("/Transaction")
    public ResponseEntity<?> transaction(@RequestBody TransactionDTO transactionDTO) {
        try {
            // Validate both Owner and Receiver's account in a single function
            if (!isValidAccount(transactionDTO.getAccNoOwner()) || !isValidAccount(transactionDTO.getAccNoReceive())) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Account verification failed.");
            }

            // Retrieve account details for Owner and Receiver
            AccountPayload ownerPayload = transactionService.getAccountDetail(checkBalanceUrl, transactionDTO.getAccNoOwner());
            AccountPayload receiverPayload = transactionService.getAccountDetail(checkBalanceUrl, transactionDTO.getAccNoReceive());

            if (ownerPayload == null || receiverPayload == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Failed to retrieve account details for Owner or Receiver.");
            }

            // Check if Owner has sufficient balance
            if (ownerPayload.getBalance().compareTo(transactionDTO.getAmount()) < 0) {
                return ResponseEntity.status(HttpStatus.NOT_ACCEPTABLE).body("Insufficient balance in Owner's account.");
            }

            // Deduct balance from Owner and add it to Receiver
            ownerPayload.setBalance(ownerPayload.getBalance().subtract(transactionDTO.getAmount()));
            receiverPayload.setBalance(receiverPayload.getBalance().add(transactionDTO.getAmount()));

            // Publish account balance updates to Kafka
            boolean ownerUpdateSuccess = transactionService.updateAccountBalance("account-updates", ownerPayload);
            boolean receiverUpdateSuccess = transactionService.updateAccountBalance("account-updates", receiverPayload);

            if (ownerUpdateSuccess && receiverUpdateSuccess) {
                // Record the transaction
                Transaction transaction = transactionService.transaction(new Transaction(
                        transactionDTO.getAccNoOwner(),
                        transactionDTO.getAccNoReceive(),
                        transactionDTO.getAmount(),
                        TransacType.Transaction));

                // Save Transaction to Database
                transactionService.transaction(transaction);

                return ResponseEntity.status(HttpStatus.OK).body("Transaction completed successfully: " + transaction);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_ACCEPTABLE).body("Error while updating balances.");
            }
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error while processing transaction: " + e.getMessage());
        }
    }

    @PostMapping("/Deposit")
    public ResponseEntity<?> deposit(@RequestBody TransactionDTO transactionDTO) {
        try {
            // Validate Owner's account
            if (!transactionService.isAccountValid(checkAccountUrl, transactionDTO.getAccNoOwner())) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Owner Account verification failed.");
            }

            // Retrieve account details for Owner
            AccountPayload ownerPayload = transactionService.getAccountDetail(checkBalanceUrl, transactionDTO.getAccNoOwner());

            // Add balance to Owner's account
            ownerPayload.setBalance(ownerPayload.getBalance().add(transactionDTO.getAmount()));

            // Publish account balance update to Kafka
            boolean ownerUpdateSuccess = transactionService.updateAccountBalance("account-updates", ownerPayload);

            if (ownerUpdateSuccess) {
                Transaction transaction = transactionService.transaction(
                        new Transaction(
                                transactionDTO.getAccNoOwner(),
                                null,
                                transactionDTO.getAmount(),
                                TransacType.Deposit));

                // Save Transaction to Database
                transactionService.transaction(transaction);

                return ResponseEntity.status(HttpStatus.OK).body(transaction);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_ACCEPTABLE).body("Error while updating balance.");
            }
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error while creating transaction: " + e.getMessage());
        }
    }

    @PostMapping("/Withdraw")
    public ResponseEntity<?> withdraw(@RequestBody TransactionDTO transactionDTO) {
        try {
            // Validate Owner's account
            if (!transactionService.isAccountValid(checkAccountUrl, transactionDTO.getAccNoOwner())) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Owner Account verification failed.");
            }

            // Retrieve account details for Owner
            AccountPayload ownerPayload = transactionService.getAccountDetail(checkBalanceUrl, transactionDTO.getAccNoOwner());

            // Subtract balance from Owner's account
            if (ownerPayload.getBalance().compareTo(transactionDTO.getAmount()) < 0) {
                return ResponseEntity.status(HttpStatus.NOT_ACCEPTABLE).body("Insufficient balance in Owner's account.");
            }
            ownerPayload.setBalance(ownerPayload.getBalance().subtract(transactionDTO.getAmount()));

            // Publish account balance update to Kafka
            boolean ownerUpdateSuccess = transactionService.updateAccountBalance("account-updates", ownerPayload);

            if (ownerUpdateSuccess) {
                Transaction transaction = transactionService.transaction(
                        new Transaction(
                                transactionDTO.getAccNoOwner(),
                                null,
                                transactionDTO.getAmount(),
                                TransacType.Withdraw));

                // Save Transaction to Database
                transactionService.transaction(transaction);


                return ResponseEntity.status(HttpStatus.OK).body(transaction);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_ACCEPTABLE).body("Error while updating balance.");
            }
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error while creating transaction: " + e.getMessage());
        }
    }

    @GetMapping("/GetTransByAccNo")
    public ResponseEntity<?> getTransactionsByAccountNo(@RequestParam Long AccNo){
        try {
            return ResponseEntity.status(HttpStatus.OK).body(transactionService.getAllTransactionByAccount(AccNo));
        }catch (Exception e){
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error while Request Transaction by Account: "+e);
        }
    }
}
