package com.customer.service;

import java.util.List;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.customer.config.kafka.KafkaResponseHandler;
import com.customer.model.Address;
import com.customer.model.Customer;
import com.customer.repository.AddressRepository;
import com.customer.repository.CustomerRepository;
import com.customer.service.kafka.KafkaProducerService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class CustomerService {

    private static final Logger log = LoggerFactory.getLogger(CustomerService.class);

    private final CustomerRepository customerRepository;

    private final AddressRepository addressRepository;

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
                throw new RuntimeException("Customer with this national ID already exists");
            }

            // Save the customer
            Customer savedCustomer = customerRepository.save(customer);

            // Save the addresses
            for (Address address : addresses) {
                address.setCustomer(savedCustomer);
                addressRepository.save(address);
            }

            return savedCustomer;
        } catch (RuntimeException e) {
            log.error("Unexpected error during customer creation: {}", e.getClass().getName(), e);
            throw new RuntimeException("An unexpected error occurred.", e);
        }
    }

    // Check if customer exists by ID
    public boolean existsById(UUID customerId) {
        return customerRepository.existsByCustomerId(customerId);
    }

    // Get customer by ID (including addresses)
    public Customer getCustomerById(UUID customerId) {
        return customerRepository.findById(customerId).get();
    }

    // Get all customers
    public List<Customer> getAllCustomers() {
        return customerRepository.findAll();
    }

    // Update customer (and addresses if necessary)
    public Customer updateCustomer(UUID customerId, Customer customerDetails) {
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new RuntimeException("Customer not found"));
        
        customer.setFirstName(customerDetails.getFirstName());
        customer.setLastName(customerDetails.getLastName());
        customer.setEmail(customerDetails.getEmail());
        customer.setPhoneNumber(customerDetails.getPhoneNumber());
        customer.setNationalId(customerDetails.getNationalId());
        customer.setDateOfBirth(customerDetails.getDateOfBirth());
        customer.setStatus(customerDetails.getStatus());
        
        return customerRepository.save(customer);
    }
}
