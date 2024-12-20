package com.account.controller;

import java.util.ArrayList;
import java.util.List;

import com.account.model.DTO.AccountDTO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.account.model.Account;
import com.account.service.AccountService;

@RestController
@RequestMapping("/accounts")
@CrossOrigin(origins = "http://localhost:8081")
public class AccountController {

    @Autowired
    private AccountService accountService;

    @GetMapping("/checkAccount")
    public ResponseEntity<?> checkAccountExists(@RequestBody AccountDTO request) {
        try{
            return ResponseEntity.status(HttpStatus.FOUND).body(accountService.checkBalance(request.getAccNo()).isPresent());
        }catch (Exception e){
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        }
    }

    /**
     * Check the balance of an account by accNo.
     *
     * @param request.getAccNo() The account number to check.
     * @return ResponseEntity with the account details or bad request if not found.
     */
    @GetMapping("/checkBalance")
    public ResponseEntity<?> checkBalance(@RequestBody AccountDTO request) {
        try {
            Account account = accountService.checkBalance(request.getAccNo()).get();
            
            return ResponseEntity.status(HttpStatus.FOUND).body(account);
        }catch (IllegalArgumentException e){
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        }
    }

    /**
     * Create a new account.
     *
     * @param account The account details to create.
     * @return ResponseEntity with success or error message.
     */
    @PostMapping("/createAccount")
    public ResponseEntity<?> createAccount(@RequestBody Account account){
        try {
            Account createdAccount = accountService.createAccount(
                    account.getIDCNo(),
                    account.getName(),
                    account.getBalance()
            );
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body("Account created successfully: " + createdAccount);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body("Error creating account: " + e.getMessage());
        }
    }

    /**
     * Delete an account by accNo.
     *
     * @param accNo The account number to delete.
     */
    @DeleteMapping("/deleteAccount")
    public ResponseEntity<String> deleteAccount(@RequestBody Long accNo) {
        try {
            accountService.deleteAccount(accNo);
            return ResponseEntity.status(HttpStatus.OK).body("Account deleted successfully.");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body("Error deleting account: " + e.getMessage());
        }
    }

    @GetMapping("/getAllAccounts")
    public ResponseEntity<?> getAllAccounts() {
        try {
            List<Account> accounts = new ArrayList<>();
            accountService.getAllAccounts().forEach(accounts::add);
            return ResponseEntity.status(HttpStatus.FOUND).body(accounts);
        }catch(Exception e){
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Error: "+e);
        }
    }
}
