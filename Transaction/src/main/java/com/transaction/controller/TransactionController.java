package com.transaction.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.transaction.model.DTO.TransactionDTO;
import com.transaction.model.Transaction;
import com.transaction.service.TransactionProcess;
import com.transaction.service.TransactionService;

import lombok.RequiredArgsConstructor;

@Component
@RestController
@RequiredArgsConstructor
@RequestMapping("/transactions")
@CrossOrigin(origins = "http://localhost:8082")
public class TransactionController {

    private final TransactionService transactionService;

    private final TransactionProcess transactionProcess;

    @PostMapping("/Transaction")
    public ResponseEntity<?> transaction(@RequestBody TransactionDTO transactionDTO) {
        try {
            Transaction processedTransaction = transactionProcess.transactionProcess(transactionDTO);
            return ResponseEntity.status(HttpStatus.OK).body(processedTransaction);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Invalid account details: " + e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error while processing transaction: " + e.getMessage());
        }
    }

    @PostMapping("/Deposit")
    public ResponseEntity<?> deposit(@RequestBody TransactionDTO transactionDTO) {
        try {
            Transaction processedTransaction = transactionProcess.depositProcess(transactionDTO);
            return ResponseEntity.status(HttpStatus.OK).body(processedTransaction);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error while creating transaction: " + e.getMessage());
        }
    }

    @PostMapping("/Withdraw")
    public ResponseEntity<?> withdraw(@RequestBody TransactionDTO transactionDTO) {
        try {
            Transaction processedTransaction = transactionProcess.withdrawProcess(transactionDTO);
            return ResponseEntity.status(HttpStatus.OK).body(processedTransaction);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Invalid account details: " + e.getMessage());
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
