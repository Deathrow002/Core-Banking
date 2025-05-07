package com.customer.service;

import java.util.List;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.customer.model.Address;
import com.customer.model.Customer;
import com.customer.repository.AddressRepository;
import com.customer.repository.CustomerRepository;

@Service
public class CustomerService {

    @Autowired
    private CustomerRepository customerRepository;

    @Autowired
    private AddressRepository addressRepository;

    // Create a new customer with addresses
    public Customer createCustomer(Customer customer, List<Address> addresses) {
        customer.setAddresses(addresses); // Set addresses
        customerRepository.save(customer);
        // Save each address separately to ensure the relation with customer is persisted
        for (Address address : addresses) {
            address.setCustomer(customer);
            addressRepository.save(address);
        }
        return customer;
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
