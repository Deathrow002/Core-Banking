package com.customer.repository;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.customer.model.Customer;

import lombok.NonNull;

@Repository
public interface CustomerRepository extends JpaRepository<Customer, UUID> {
    boolean existsByCustomerId(@NonNull UUID customerId);
    Optional<Customer> findByEmail(@NonNull String email);
    boolean existsByNationalId(@NonNull String nationalId);
    boolean existsByEmail(@NonNull String email);
    boolean existsByPhoneNumber(@NonNull String phoneNumber);
}