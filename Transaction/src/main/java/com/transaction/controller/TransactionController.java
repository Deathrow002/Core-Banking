package com.transaction.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.transaction.model.TransacType;
import com.transaction.model.Transaction;
import com.transaction.service.TransactionService;

import java.util.List;

@RestController
@RequestMapping("/transaction")
@CrossOrigin(origins = "http://localhost:8082")
public class TransactionController {

    @Autowired
    private TransactionService transactionService;

    @PostMapping("/transaction")
    public ResponseEntity<Transaction> transaction(@RequestBody Long AccNoOwner, @RequestBody Long AccNoReceive, @RequestBody Float Amount){
        return ResponseEntity.status(HttpStatus.OK).body(transactionService.transaction(new Transaction(AccNoOwner, AccNoReceive, Amount, TransacType.Transaction)));
    }

    @PostMapping("/deposit")
    public ResponseEntity<Transaction> deposit(@RequestBody Long AccNoOwner, @RequestBody Long AccNoReceive, @RequestBody Float Amount){
        return ResponseEntity.status(HttpStatus.OK).body(transactionService.transaction(new Transaction(AccNoOwner, AccNoReceive, Amount, TransacType.Deposit)));
    }

    @PostMapping("/withdraw")
    public ResponseEntity<Transaction> withdraw(@RequestBody Long AccNoOwner, @RequestBody Long AccNoReceive, @RequestBody Float Amount){
        return ResponseEntity.status(HttpStatus.OK).body(transactionService.transaction(new Transaction(AccNoOwner, AccNoReceive, Amount, TransacType.Withdraw)));
    }

    @GetMapping("/GetTransByAccNo")
    public ResponseEntity<?> getTransactionsByAccountNo(@RequestParam Long AccNo){
        try {
            return ResponseEntity.status(HttpStatus.OK).body(transactionService.getAllTransactionByAccount(AccNo));
        }catch (Exception e){
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error: "+e);
        }
    }
}
