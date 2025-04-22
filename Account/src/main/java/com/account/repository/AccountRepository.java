package com.account.repository;

import java.math.BigInteger;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.account.model.Account;

@Repository
public interface AccountRepository extends JpaRepository<Account, BigInteger> {
    @Override
    boolean existsById(BigInteger id);
}
