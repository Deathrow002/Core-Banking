package com.authentication.repository;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.authentication.models.UserAuth;

@Repository
public interface UserAuthRepository extends JpaRepository<UserAuth, UUID> {
    Optional<UserAuth> findByEmail(String email);
}