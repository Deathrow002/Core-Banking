package com.customer.exception;

/**
 * Exception thrown when a customer already exists in the system.
 * This exception is typically used to indicate that an attempt to create
 * a new customer with an existing identifier (like email or ID) has failed.
 */
public class CustomerAlreadyExistsException extends RuntimeException {
    public CustomerAlreadyExistsException(String message) {
        super(message);
    }
}