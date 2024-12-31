package com.transaction.controller;

import com.transaction.model.DTO.TransactionDTO;
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
    public ResponseEntity<?> transaction(@RequestBody TransactionDTO transactionDTO){
        try {
            return ResponseEntity.status(HttpStatus.OK).body(transactionService.transaction(
                    new Transaction(
                            transactionDTO.getAccNoOwner(),
                            transactionDTO.getAccNoReceive(),
                            transactionDTO.getAmount(),
                            TransacType.Transaction)));
        }catch (Exception e){
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error: "+e);
        }
    }

    @PostMapping("/deposit")
    public ResponseEntity<?> deposit(@RequestBody TransactionDTO transactionDTO){
        try {
            return ResponseEntity.status(HttpStatus.OK).body(transactionService.transaction(
                    new Transaction(
                            transactionDTO.getAccNoOwner(),
                            transactionDTO.getAccNoOwner(),
                            transactionDTO.getAmount(),
                            TransacType.Deposit)));
        }catch (Exception e){
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error: "+e);
        }
    }

    @PostMapping("/withdraw")
    public ResponseEntity<?> withdraw(@RequestBody TransactionDTO transactionDTO){
        try{
            return ResponseEntity.status(HttpStatus.OK).body(transactionService.transaction(
                    new Transaction(
                            transactionDTO.getAccNoOwner(),
                            transactionDTO.getAccNoReceive(),
                            transactionDTO.getAmount(),
                            TransacType.Withdraw)));
        }catch (Exception e){
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error: "+e);
        }
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
