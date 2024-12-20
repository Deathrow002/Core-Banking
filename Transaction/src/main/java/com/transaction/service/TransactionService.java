package com.transaction.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.transaction.model.Transaction;
import com.transaction.repository.TransactionRepository;
import org.springframework.web.client.RestTemplate;

@Service
public class TransactionService {
    private TransactionRepository transactionRepository;

    private final RestTemplate restTemplate;

    @Autowired
    public TransactionService(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    public Transaction transaction(Transaction transaction){

        return transactionRepository.save(transaction);
    }

    public List<Transaction> getAllTransactionByAccount(Long AccNo){
        return transactionRepository.getAllTransactionByAccount(AccNo);
    }
}
