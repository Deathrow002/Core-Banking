package com.account.config.kafka;

import java.util.HashMap;
import java.util.Map;

import org.apache.kafka.common.header.Header;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import com.account.config.JWT.JwtUtils;

import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor  
public class JwtKafkaMessageConverter {
    
    private static final Logger log = LoggerFactory.getLogger(JwtKafkaMessageConverter.class);
    
    private final JwtUtils jwtUtils;
    
    /**
     * Extracts and validates JWT information from Kafka message headers
     */
    public JwtInfo extractJwtInfo(org.apache.kafka.common.header.Headers headers) {
        Header authHeader = headers.lastHeader("Authorization");
        if (authHeader == null) {
            log.debug("No Authorization header found in Kafka message");
            return new JwtInfo(null, null, null, null, false, "No Authorization header found");
        }
        
        String jwtToken = new String(authHeader.value());
        log.info("Extracted JWT token from Kafka message headers");
        
        // Validate and extract claims from JWT
        if (jwtUtils.isTokenValid(jwtToken)) {
            String username = jwtUtils.extractUsername(jwtToken);
            String role = jwtUtils.extractRole(jwtToken);
            String customerId = jwtUtils.extractCustomerId(jwtToken);
            
            log.info("JWT validation successful - Username: {}, Role: {}, CustomerId: {}", 
                    username, role, customerId);
            
            return new JwtInfo(jwtToken, username, role, customerId, true, null);
        } else {
            log.warn("Invalid JWT token received in Kafka message");
            return new JwtInfo(jwtToken, null, null, null, false, "Invalid JWT token");
        }
    }
    
    /**
     * Creates a security context map from JWT information
     */
    public Map<String, Object> createSecurityContext(JwtInfo jwtInfo) {
        Map<String, Object> context = new HashMap<>();
        if (jwtInfo.isValid()) {
            context.put("authenticated", true);
            context.put("username", jwtInfo.getUsername());
            context.put("role", jwtInfo.getRole());
            context.put("customerId", jwtInfo.getCustomerId());
            context.put("jwtToken", jwtInfo.getToken());
        } else {
            context.put("authenticated", false);
            context.put("error", jwtInfo.getError());
        }
        return context;
    }
    
    /**
     * JWT information container
     */
    public static class JwtInfo {
        private final String token;
        private final String username;
        private final String role;
        private final String customerId;
        private final boolean valid;
        private final String error;
        
        public JwtInfo(String token, String username, String role, String customerId, boolean valid, String error) {
            this.token = token;
            this.username = username;
            this.role = role;
            this.customerId = customerId;
            this.valid = valid;
            this.error = error;
        }
        
        public String getToken() { return token; }
        public String getUsername() { return username; }
        public String getRole() { return role; }
        public String getCustomerId() { return customerId; }
        public boolean isValid() { return valid; }
        public String getError() { return error; }
        
        @Override
        public String toString() {
            return String.format("JwtInfo{valid=%s, username='%s', role='%s', customerId='%s', error='%s'}", 
                               valid, username, role, customerId, error);
        }
    }
}
