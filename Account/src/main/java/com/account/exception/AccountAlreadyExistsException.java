package com.account.exception;

/**
 * Exception thrown when an account already exists in the system.
 * This exception is typically used to indicate that an attempt to create
 * a new account with an existing identifier (like account number) has failed.
 */
public class AccountAlreadyExistsException extends RuntimeException {
    public AccountAlreadyExistsException(String message) {
        super(message);
    }
}
