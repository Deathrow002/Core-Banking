package com.account.repository;

import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Repository;

import com.account.model.Account;

@Repository
public interface AccountRepository extends JpaRepository<Account, UUID> {
    @Override
    boolean existsById(@NonNull UUID id);
}
