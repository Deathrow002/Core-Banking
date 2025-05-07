package com.customer.repository;

import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.customer.model.Address;

public interface AddressRepository extends JpaRepository<Address, UUID> {
}
