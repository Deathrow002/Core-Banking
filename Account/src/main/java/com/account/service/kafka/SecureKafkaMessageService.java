package com.account.service.kafka;

import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.account.config.kafka.JwtKafkaMessageConverter;

import lombok.RequiredArgsConstructor;

/**
 * Service to demonstrate JWT-secured Kafka message processing
 * This service shows how to use the custom JwtKafkaMessageConverter
 * to extract and validate JWT tokens from Kafka message headers
 */
@Service
@RequiredArgsConstructor
public class SecureKafkaMessageService {
    
    private static final Logger log = LoggerFactory.getLogger(SecureKafkaMessageService.class);
    
    private final JwtKafkaMessageConverter jwtMessageConverter;
    
    /**
     * Process a message with JWT authentication validation
     * This method demonstrates how to use the JWT message converter
     * to extract authentication information from Kafka headers
     */
    public void processSecureMessage(org.apache.kafka.common.header.Headers kafkaHeaders, String messageContent) {
        log.info("Processing secure message with JWT validation");
        
        // Extract JWT information from Kafka headers
        JwtKafkaMessageConverter.JwtInfo jwtInfo = jwtMessageConverter.extractJwtInfo(kafkaHeaders);
        
        if (!jwtInfo.isValid()) {
            log.error("Message processing failed - Invalid JWT: {}", jwtInfo.getError());
            throw new SecurityException("Invalid or missing JWT token: " + jwtInfo.getError());
        }
        
        // Create security context for the authenticated user
        Map<String, Object> securityContext = jwtMessageConverter.createSecurityContext(jwtInfo);
        
        log.info("Message processing authorized for user: {} with role: {} for customer: {}", 
                jwtInfo.getUsername(), jwtInfo.getRole(), jwtInfo.getCustomerId());
        
        // Process the message with the security context
        processMessageWithSecurity(messageContent, securityContext, jwtInfo);
    }
    
    /**
     * Process the actual message content with security context
     */
    private void processMessageWithSecurity(String messageContent, Map<String, Object> securityContext, 
                                          JwtKafkaMessageConverter.JwtInfo jwtInfo) {
        
        log.info("Processing message content: {} with security context", messageContent);
        
        // Example security checks
        if (securityContext.get("authenticated").equals(true)) {
            String role = jwtInfo.getRole();
            String customerId = jwtInfo.getCustomerId();
            
            // Role-based processing
            switch (role) {
                case "ROLE_ADMIN" -> log.info("Admin user processing message - full access granted");
                case "ROLE_MANAGER" -> log.info("Manager user processing message - limited access granted");
                case "ROLE_USER" -> {
                    log.info("Regular user processing message for customer: {}", customerId);
                    // Additional customer-specific validation could be added here
                }
                default -> log.warn("Unknown role: {} - processing with limited access", role);
            }
            
            // Simulate message processing
            log.info("Message processed successfully by user: {}", jwtInfo.getUsername());
        } else {
            throw new SecurityException("User not authenticated");
        }
    }
    
    /**
     * Validate that a customer has permission to access account data
     */
    public boolean validateCustomerAccess(String jwtCustomerId, String accountCustomerId) {
        if (jwtCustomerId == null || accountCustomerId == null) {
            return false;
        }
        
        boolean hasAccess = jwtCustomerId.equals(accountCustomerId);
        log.info("Customer access validation - JWT Customer: {}, Account Customer: {}, Access: {}", 
                jwtCustomerId, accountCustomerId, hasAccess);
        
        return hasAccess;
    }
}
