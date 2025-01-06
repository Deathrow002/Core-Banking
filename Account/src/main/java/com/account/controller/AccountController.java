package com.account.controller;

import java.math.BigInteger;
import java.util.List;
import java.util.NoSuchElementException;

import com.account.model.DTO.AccountDTO;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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

    private static final Logger log = LoggerFactory.getLogger(AccountController.class);
    @Autowired
    private AccountService accountService;

    @GetMapping("/validateAccount")
    public ResponseEntity<?> checkAccountExists(@RequestParam BigInteger accNo) {
        try {
            boolean validate = accountService.checkBalance(accNo).isPresent();
            if (validate) {
                return ResponseEntity.ok(true);
            } else {
                // If account does not exist, return 404 (Not Found)
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Account not found.");
            }
        } catch (Exception e) {
            // Log the exception for debugging
            log.error("Error while checking account existence for account {}: {}", accNo, e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error checking account existence.");
        }
    }

    @GetMapping("/getAccount")
    public ResponseEntity<?> getAccount(@RequestParam BigInteger accNo) {
        try {
            Account account = accountService.checkBalance(accNo).orElseThrow(() -> new NoSuchElementException("Account not found."));
            return ResponseEntity.ok(account);
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error checking balance.");
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

    @PostMapping("/createAccount")
    public ResponseEntity<?> createAccount(@RequestBody AccountDTO accountDTO) {
        try {
            Account createdAccount = accountService.createAccount(accountDTO);
            return ResponseEntity.status(HttpStatus.CREATED).body(createdAccount);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error while creating account: "+e.getMessage());
        }
    }

    @PutMapping("/updateAccountBalance")
    public ResponseEntity<?> updateAccountBalance(@RequestBody AccountDTO accountDTO){
        try{
            Account updatedAccount = accountService.updateAccountBalance(accountDTO);
            return ResponseEntity.status(HttpStatus.OK).body(updatedAccount);
        }catch (Exception e){
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error while Updating account: "+e.getMessage());
        }
    }

    @DeleteMapping("/deleteAccount")
    public ResponseEntity<String> deleteAccount(@RequestParam BigInteger accNo) {
        try {
            accountService.deleteAccount(accNo);
            return ResponseEntity.ok("Account deleted successfully.");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error deleting account.");
        }
    }
}

