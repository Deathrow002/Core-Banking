package com.account.service;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.jetbrains.annotations.NotNull;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import com.account.exception.AccountAlreadyExistsException;
import com.account.model.Account;
import com.account.model.DTO.AccountDTO;
import com.account.repository.AccountRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class AccountService {
    String checkCustomerUrl  = "http://CUSTOMER-SERVICE/customers/validateById";

    private static final Logger log = LoggerFactory.getLogger(AccountService.class);
    
    private final AccountRepository accountRepository;

    private final RestTemplate restTemplate;

    //Check Account Balance
    public Optional<Account> checkBalance(UUID AccNo){
        return accountRepository.findById(AccNo);
    }

    //Create Account
    @Transactional
    public Account createAccount(@NotNull AccountDTO accountDTO) {
        try {
            log.debug("Starting account creation for customer ID: {}", accountDTO.getCustomerId());

            // Check if Customer ID already exists
            if(!validateCustomer(accountDTO.getCustomerId())){
                log.error("Customer ID {} does not exist", accountDTO.getCustomerId());
                throw new AccountAlreadyExistsException("Customer ID does not exist");
            }

            // Create and save the account
            Account account = new Account(
                accountDTO.getCustomerId(),
                accountDTO.getBalance(),
                accountDTO.getCurrency()
            );

            // Save the account
            Account savedAccount = accountRepository.save(account);

            // Log success
            log.info("Account successfully created for customer ID: {}", accountDTO.getCustomerId());
            return savedAccount;
        } catch (AccountAlreadyExistsException e) {
            log.error("Account creation failed: {}", e.getMessage());
            throw new AccountAlreadyExistsException("Customer ID does not exist");
        } catch (Exception e) {
            log.error("Error during account creation: {}", e.getMessage(), e);
            throw new RuntimeException("Account creation failed", e);
        }
    }

    //Update Account Balance
    @Transactional
    public Account updateAccountBalance(@NotNull AccountDTO accountDTO){
        //Prepare Payload
        Account payload = accountRepository.findById(UUID.fromString(accountDTO.getAccountId().toString())).get();

        //Set New Balance to Payload
        payload.setBalance(accountDTO.getBalance());

        //Update Balance
        return accountRepository.save(payload);
    }

    //Delete Account
    public void deleteAccount(UUID AccNo){
        accountRepository.deleteById(AccNo);
    }

    //Get All Accounts
    public List<Account> getAllAccounts(){
        return accountRepository.findAll();
    }

    //Get Account by Customer ID
    public List<Account> searchByCustomerId(UUID customerId){
        return accountRepository.findByCustomerId(customerId);
    }

    //Check if Account Exists
    public boolean existsById(UUID AccNo) {
        return accountRepository.existsById(AccNo);
    }

    //Check if Customer Exists
    public boolean validateCustomer(UUID customerId) {
        try {
            String requestUrl = checkCustomerUrl + "?customerId=" + customerId;
            ResponseEntity<Boolean> response = restTemplate.getForEntity(requestUrl, Boolean.class);
            log.info("Response: {}", response);

            if (response.getStatusCode().is2xxSuccessful()) {
                log.info("Valid Response: {}", response.getBody());
                return Boolean.TRUE.equals(response.getBody());
            } else {
                log.warn("Non-success HTTP response: {} for customer {} from URL: {}",
                    response.getStatusCode(), customerId, requestUrl);
                return false;
            }
        } catch (org.springframework.web.client.RestClientException e) {
            log.error("RestClientException while validating customer {}: {}", customerId, e.getMessage());
            return false;
        } catch (IllegalArgumentException e) {
            log.error("IllegalArgumentException while validating customer {}: {}", customerId, e.getMessage());
            return false;
        }
    }
}
