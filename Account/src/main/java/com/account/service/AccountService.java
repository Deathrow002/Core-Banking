package com.account.service;

import java.util.List;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.account.model.Account;
import com.account.model.DTO.AccountDTO;
import com.account.repository.AccountRepository;

@Service
public class AccountService {
    @Autowired
    private AccountRepository accountRepository;

    public Optional<Account> checkAcc(Long AccNo){
        return accountRepository.findById(AccNo);
    }

    public Optional<Account> checkBalance(Long AccNo){
        return accountRepository.findById(AccNo);
    }

    public Account createAccount(AccountDTO accountDTO){
        return accountRepository.save(new Account(accountDTO.getIdcNo(), accountDTO.getName(), accountDTO.getBalance()));
    }

    public void deleteAccount(Long AccNo){
        accountRepository.deleteById(AccNo);
    }

    public List<Account> getAllAccounts(){
        return accountRepository.findAll();
    }
}
