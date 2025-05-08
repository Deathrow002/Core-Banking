package com.customer.controller;

import java.util.List;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.customer.model.Customer;
import com.customer.service.CustomerService;

@RestController
@RequestMapping("/customers")
public class CustomerController {

    @Autowired
    private CustomerService customerService;

    // Create a new customer with addresses
    @PostMapping
    public ResponseEntity<Customer> createCustomer(@RequestBody Customer customer) {
        Customer createdCustomer = customerService.createCustomer(customer, customer.getAddresses());
        return new ResponseEntity<>(createdCustomer, HttpStatus.CREATED);
    }

    // Get customer by ID
    @GetMapping
    public ResponseEntity<Customer> getCustomerById(@RequestParam UUID customerId) {
        Customer customer = customerService.getCustomerById(customerId);
        return new ResponseEntity<>(customer, HttpStatus.OK);
    }

    // Get all customers
    @GetMapping("/all")
    public ResponseEntity<List<Customer>> getAllCustomers() {
        List<Customer> customers = customerService.getAllCustomers();
        return new ResponseEntity<>(customers, HttpStatus.OK);
    }

    // Update an existing customer
    @PutMapping
    public ResponseEntity<Customer> updateCustomer(@RequestParam UUID customerId, @RequestBody Customer customerDetails) {
        Customer updatedCustomer = customerService.updateCustomer(customerId, customerDetails);
        return new ResponseEntity<>(updatedCustomer, HttpStatus.OK);
    }
}
