package com.transaction.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.transaction.model.Transaction;
import org.springframework.data.jpa.repository.Query;

public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    @Query("SELECT t FROM Transaction t WHERE t.AccNoOwner = :AccNo")
    List<Transaction> getAllTransactionByAccount(Long AccNo);
}
