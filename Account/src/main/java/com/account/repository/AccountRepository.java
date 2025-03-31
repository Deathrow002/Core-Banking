package com.account.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.account.model.Account;
import org.springframework.stereotype.Repository;

import java.math.BigInteger;

@Repository
public interface AccountRepository extends JpaRepository<Account, BigInteger> {
    boolean existsById(BigInteger id);
}
