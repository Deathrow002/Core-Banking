package com.account.controller;

import java.util.List;
import java.util.NoSuchElementException;

import com.account.model.DTO.AccountDTO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.account.model.Account;
import com.account.service.AccountService;

@RestController
@RequestMapping("/accounts")
@CrossOrigin(origins = "http://localhost:8081")
public class AccountController {

    @Autowired
    private AccountService accountService;

    @GetMapping("/checkAccount")
    public ResponseEntity<?> checkAccountExists(@RequestParam Long accNo) {
        try {
            boolean exists = accountService.checkBalance(accNo).isPresent();
            return ResponseEntity.ok(exists);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error checking account existence.");
        }
    }

    @GetMapping("/checkBalance")
    public ResponseEntity<?> checkBalance(@RequestParam Long accNo) {
        try {
            Account account = accountService.checkBalance(accNo).orElseThrow(() -> new NoSuchElementException("Account not found."));
            return ResponseEntity.ok(account);
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error checking balance.");
        }
    }

    @PostMapping("/createAccount")
    public ResponseEntity<?> createAccount(@RequestBody AccountDTO accountDTO) {
        try {
            Account createdAccount = accountService.createAccount(accountDTO);
            return ResponseEntity.status(HttpStatus.CREATED).body(createdAccount);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error creating account: "+e.getMessage());
        }
    }

    @DeleteMapping("/deleteAccount")
    public ResponseEntity<String> deleteAccount(@RequestParam Long accNo) {
        try {
            accountService.deleteAccount(accNo);
            return ResponseEntity.ok("Account deleted successfully.");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error deleting account.");
        }
    }

    @GetMapping("/getAllAccounts")
    public ResponseEntity<?> getAllAccounts() {
        try {
            List<Account> accounts = accountService.getAllAccounts();
            return ResponseEntity.ok(accounts);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error fetching accounts.");
        }
    }
}

