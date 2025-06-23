package com.customer.service;

import java.util.List;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.customer.exception.CustomerAlreadyExistsException;
import com.customer.model.Address;
import com.customer.model.Customer;
import com.customer.repository.CustomerRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class CustomerService {

    private static final Logger log = LoggerFactory.getLogger(CustomerService.class);

    private final CustomerRepository customerRepository;

    // Create a new customer with addresses
    @Transactional
    public Customer createCustomer(Customer customer, List<Address> addresses) {
        try {
            // Validate input
            if (customer.getNationalId() == null || customer.getFirstName() == null) {
                throw new IllegalArgumentException("Customer details are incomplete.");
            }

            // Check if customer already exists
            if (customerRepository.existsByNationalId(customer.getNationalId())) {
                throw new CustomerAlreadyExistsException("Customer with this national ID already exists");
            }

            // Set addresses to customer and set customer in each address
            for (Address address : addresses) {
                address.setCustomer(customer);
                customer.getAddresses().add(address);
            }

            // Save the customer (addresses will be saved via cascade)
            Customer savedCustomer = customerRepository.save(customer);

            return savedCustomer;
        }
        catch (IllegalArgumentException e) {
            log.error("Invalid customer details: {}", e.getMessage());
            throw e;
        } catch (CustomerAlreadyExistsException e) {
            log.error("Customer already exists: {}", e.getMessage());
            throw e;
        }catch (Exception e) {
            log.error("Unexpected error while creating customer: {}", e.getMessage());
            throw new RuntimeException("An error occurred while creating the customer.", e);
        }
    }

    // Custumer Validation
    public boolean validateCustomer(UUID customerId, String email) {
        try{
            return customerRepository.existsById(customerId) && customerRepository.existsByEmail(email);
        } catch (Exception e) {
            log.error("Error validating customer: {}", e.getMessage());
            throw new RuntimeException("An error occurred while validating the customer.", e);
        }
    }

    // Check if customer exists by ID
    public boolean existsById(UUID customerId) {
        try {
            return customerRepository.existsById(customerId);
        } catch (Exception e) {
            log.error("Error checking if customer exists by ID: {}", e.getMessage());
            throw new RuntimeException("An error occurred while checking customer existence.", e);
        }
    }

    // Get customer by ID (including addresses)
    public Customer getCustomerById(UUID customerId) {
        try {
            return customerRepository.findById(customerId)
                    .orElseThrow(() -> new RuntimeException("Customer not found"));
        } catch (RuntimeException e) {
            log.error("Error retrieving customer by ID: {}", e.getMessage());
            throw new RuntimeException("An error occurred while retrieving the customer.", e);
        }
    }

    // Get all customers
    public List<Customer> getAllCustomers() {
        try {
            return customerRepository.findAll();
        } catch (Exception e) {
            log.error("Error retrieving all customers: {}", e.getMessage());
            throw new RuntimeException("An error occurred while retrieving customers.", e);
        }
    }

    // Update customer (and addresses if necessary)
    @Transactional
    public Customer updateCustomer(UUID customerId, Customer customerDetails) {
        try {
            Customer existingCustomer = customerRepository.findById(customerId)
                    .orElseThrow(() -> new RuntimeException("Customer not found"));

            // Update customer details
            existingCustomer.setFirstName(customerDetails.getFirstName());
            existingCustomer.setLastName(customerDetails.getLastName());
            existingCustomer.setNationalId(customerDetails.getNationalId());
            existingCustomer.setEmail(customerDetails.getEmail());

            // Save updated customer
            return customerRepository.save(existingCustomer);
        } catch (RuntimeException e) {
            log.error("Error updating customer: {}", e.getMessage());
            throw new RuntimeException("An error occurred while updating the customer.", e);
        }
    }
}
