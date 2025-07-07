package com.transaction.controller;

import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.transaction.model.DTO.TransactionDTO;
import com.transaction.model.Transaction;
import com.transaction.service.TransactionProcess;
import com.transaction.service.TransactionService;

import lombok.RequiredArgsConstructor;
import reactor.core.publisher.Mono;

@RestController
@RequiredArgsConstructor
@RequestMapping("/transactions")
@CrossOrigin(origins = "http://localhost:8082")
public class TransactionController {

    private final TransactionService transactionService;
    private final TransactionProcess transactionProcess;

    @PostMapping("/transaction")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('USER')")
    public Mono<ResponseEntity<Transaction>> transaction(@RequestBody TransactionDTO transactionDTO, @RequestHeader("Authorization") String authorizationHeader) {
        String jwtToken = authorizationHeader.replace("Bearer ", "");
        return transactionProcess.transactionProcess(transactionDTO, jwtToken)
                .map(tx -> ResponseEntity.status(HttpStatus.OK).body(tx));
    }

    @PostMapping("/deposit")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('USER')")
    public Mono<ResponseEntity<Transaction>> deposit(@RequestBody TransactionDTO transactionDTO, @RequestHeader("Authorization") String authorizationHeader) {
        String jwtToken = authorizationHeader.replace("Bearer ", "");
        return transactionProcess.depositProcess(transactionDTO, jwtToken)
                .map(tx -> ResponseEntity.status(HttpStatus.OK).body(tx));
    }

    @PostMapping("/withdraw")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('USER')")
    public Mono<ResponseEntity<Transaction>> withdraw(@RequestBody TransactionDTO transactionDTO, @RequestHeader("Authorization") String authorizationHeader) {
        String jwtToken = authorizationHeader.replace("Bearer ", "");
        return transactionProcess.withdrawProcess(transactionDTO, jwtToken)
                .map(tx -> ResponseEntity.status(HttpStatus.OK).body(tx));
    }

    @GetMapping("/GetTransByAccNo")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    public Mono<ResponseEntity<?>> getTransactionsByAccountNo(@RequestParam UUID AccNo){
        return transactionService.getAllTransactionByAccount(AccNo)
                .map(list -> ResponseEntity.status(HttpStatus.OK).body(list));
    }
}
