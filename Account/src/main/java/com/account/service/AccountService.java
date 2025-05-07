package com.account.service;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.jetbrains.annotations.NotNull;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.account.model.Account;
import com.account.model.DTO.AccountDTO;
import com.account.repository.AccountRepository;

@Service
public class AccountService {
    @Autowired
    private AccountRepository accountRepository;

    public Optional<Account> checkBalance(UUID AccNo){
        return accountRepository.findById(AccNo);
    }

    public Account createAccount(@NotNull AccountDTO accountDTO){
        return accountRepository.save(
                new Account(
                        accountDTO.getIdcNo(),
                        accountDTO.getName(),
                        accountDTO.getBalance()
                )
        );
    }

    public Account updateAccountBalance(@NotNull AccountDTO accountDTO){
        //Prepare Payload
        Account payload = accountRepository.findById(UUID.fromString(accountDTO.getAccNo().toString())).get();

        //Set New Balance to Payload
        payload.setBalance(accountDTO.getBalance());

        //Update Balance
        return accountRepository.save(payload);
    }

    public void deleteAccount(UUID AccNo){
        accountRepository.deleteById(AccNo);
    }

    public List<Account> getAllAccounts(){
        return accountRepository.findAll();
    }

    public boolean existsById(UUID AccNo) {
        return accountRepository.existsById(AccNo);
    }
}
