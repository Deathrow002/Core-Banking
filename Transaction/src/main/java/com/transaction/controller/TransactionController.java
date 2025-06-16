package com.transaction.controller;

import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
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
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('USER')")
    public ResponseEntity<?> transaction(@RequestBody TransactionDTO transactionDTO) {
        Transaction processedTransaction = transactionProcess.transactionProcess(transactionDTO);
        return ResponseEntity.status(HttpStatus.OK).body(processedTransaction);
    }

    @PostMapping("/Deposit")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('USER')")
    public ResponseEntity<?> deposit(@RequestBody TransactionDTO transactionDTO) {
        Transaction processedTransaction = transactionProcess.depositProcess(transactionDTO);
        return ResponseEntity.status(HttpStatus.OK).body(processedTransaction);
    }

    @PostMapping("/Withdraw")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('USER')")
    public ResponseEntity<?> withdraw(@RequestBody TransactionDTO transactionDTO) {
        Transaction processedTransaction = transactionProcess.withdrawProcess(transactionDTO);
        return ResponseEntity.status(HttpStatus.OK).body(processedTransaction);

    }

    @GetMapping("/GetTransByAccNo")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    public ResponseEntity<?> getTransactionsByAccountNo(@RequestParam UUID AccNo){
        return ResponseEntity.status(HttpStatus.OK).body(transactionService.getAllTransactionByAccount(AccNo));

    }
}
