package com.account.controller;

import java.util.List;
import java.util.NoSuchElementException;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.account.model.Account;
import com.account.model.DTO.AccountDTO;
import com.account.service.AccountService;

import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/accounts")
@CrossOrigin(origins = "http://localhost:8081")
public class AccountController {

    private static final Logger log = LoggerFactory.getLogger(AccountController.class);

    private final AccountService accountService;

    @GetMapping("/validateAccount")
    @Cacheable(value = "accountExistsCache", key = "#accNo")
    public ResponseEntity<?> checkAccountExists(@RequestParam UUID accNo) {
        try {
            boolean exists = accountService.existsById(accNo);
            if (exists) {
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
    @Cacheable(value = "accountCache", key = "#accNo")
    public ResponseEntity<?> getAccount(@RequestParam UUID accNo) {
        try {
            Account account = accountService.checkBalance(accNo).orElseThrow(() -> new NoSuchElementException("Account not found."));
            return ResponseEntity.ok(account);
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error checking balance.");
        }
    }

    @GetMapping("/getAccountByCustomerId")
    @Cacheable(value = "accountCache", key = "#customerId")
    public ResponseEntity<?> getAccountByCustomerId(@RequestParam UUID customerId) {
        try {
            List<Account> accounts = accountService.searchByCustomerId(customerId);
            if (accounts.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body("No accounts found for the given customer ID.");
            }
            return ResponseEntity.ok(accounts);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error fetching accounts.");
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
    @CacheEvict(value = {"accountExistsCache", "accountCache"}, key = "#accountDTO.accNo")
    public ResponseEntity<?> updateAccountBalance(@RequestBody AccountDTO accountDTO){
        try{
            Account updatedAccount = accountService.updateAccountBalance(accountDTO);
            return ResponseEntity.status(HttpStatus.OK).body(updatedAccount);
        }catch (Exception e){
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error while Updating account: "+e.getMessage());
        }
    }

    @DeleteMapping("/deleteAccount")
    @CacheEvict(value = {"accountExistsCache", "accountCache"}, key = "#accNo")
    public ResponseEntity<String> deleteAccount(@RequestParam UUID accNo) {
        try {
            accountService.deleteAccount(accNo);
            return ResponseEntity.ok("Account deleted successfully.");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error deleting account.");
        }
    }
}

