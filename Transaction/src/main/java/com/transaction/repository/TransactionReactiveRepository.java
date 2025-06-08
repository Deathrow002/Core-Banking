package com.transaction.repository;

import java.util.UUID;

import org.springframework.data.repository.reactive.ReactiveCrudRepository;

import com.transaction.model.Transaction;

@Repository
public interface TransactionReactiveRepository extends ReactiveCrudRepository<Transaction, UUID> {
    
}
