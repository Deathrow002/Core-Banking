package com.customer.service;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.customer.model.Address;
import com.customer.model.Customer;
import com.customer.model.DTO.AccountPayload;
import com.customer.model.DTO.CurrencyType;
import com.customer.repository.AddressRepository;
import com.customer.repository.CustomerRepository;
import com.customer.service.kafka.KafkaProducerService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

@Service
public class CustomerService {

    @Autowired
    private CustomerRepository customerRepository;

    @Autowired
    private AddressRepository addressRepository;

    @Autowired
    private final KafkaProducerService kafkaProducerService;

    public CustomerService(KafkaProducerService kafkaProducerService) {
        this.kafkaProducerService = kafkaProducerService;
    }

    // Create a new customer with addresses
    public Customer createCustomer(Customer customer, List<Address> addresses) {
        try {
            // Save the customer
            Customer savedCustomer = customerRepository.save(customer);

            // Save the addresses
            for (Address address : addresses) {
                address.setCustomer(savedCustomer);
                addressRepository.save(address);
            }

            // Serialize the Customer Payload as a JSON string
            ObjectMapper objectMapper = new ObjectMapper();

            // Create an AccountPayload object
            AccountPayload accountPayload = new AccountPayload(
                savedCustomer.getCustomerId(),
                BigDecimal.ZERO,
                CurrencyType.THB
            );

            String jsonPayload = objectMapper.writeValueAsString(accountPayload);

            // Send customer data to Kafka
            kafkaProducerService.sendMessage("customer-topic", jsonPayload.getBytes());

            return savedCustomer;
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Error creating customer: " + e.getMessage());
        }
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
