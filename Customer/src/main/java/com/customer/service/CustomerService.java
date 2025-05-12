package com.customer.service;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.customer.model.Address;
import com.customer.model.Customer;
import com.customer.model.DTO.AccountPayload;
import com.customer.model.DTO.CurrencyType;
import com.customer.repository.AddressRepository;
import com.customer.repository.CustomerRepository;
import com.customer.service.kafka.KafkaProducerService;
import com.customer.config.KafkaResponseHandler;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

@Service
public class CustomerService {

    private static final Logger log = LoggerFactory.getLogger(CustomerService.class);

    @Autowired
    private CustomerRepository customerRepository;

    @Autowired
    private AddressRepository addressRepository;

    @Autowired
    private KafkaProducerService kafkaProducerService;

    @Autowired
    private KafkaResponseHandler kafkaResponseHandler;

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

            // Serialize the Customer Payload as a JSON string
            ObjectMapper objectMapper = new ObjectMapper();
            AccountPayload accountPayload = new AccountPayload(
                savedCustomer.getCustomerId(),
                BigDecimal.ZERO,
                CurrencyType.THB
            );

            // Convert the AccountPayload object to JSON
            String jsonPayload = objectMapper.writeValueAsString(accountPayload);
            log.debug("Serialized account payload: {}", jsonPayload);

            // Generate a unique correlation ID
            String correlationId = UUID.randomUUID().toString();
            log.debug("Generated correlation ID: {}", correlationId);
            log.debug("Waiting for response with correlation ID: {}", correlationId);

            // Prepare a CompletableFuture to wait for the response
            CompletableFuture<String> responseFuture = new CompletableFuture<>();

            // Register the future in a response handler
            kafkaResponseHandler.register(correlationId, responseFuture);

            // Send customer data to Kafka with the correlation ID
            kafkaProducerService.sendMessageWithHeaders("account-create", jsonPayload, correlationId);

            // Wait for the response (timeout after 30 seconds)
            String response = responseFuture.get(30, TimeUnit.SECONDS);

            // Check the response
            if ("success".equalsIgnoreCase(response)) {
                log.info("Account creation successful for customer: {}", savedCustomer.getCustomerId());
                return savedCustomer;
            } else {
                log.error("Failed to create account: {}", response);
                throw new RuntimeException("Failed to create account: " + response);
            }
        } catch (JsonProcessingException e) {
            log.error("Error serializing account payload: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to process customer creation request.", e);
        } catch (InterruptedException | RuntimeException | ExecutionException | TimeoutException e) {
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
