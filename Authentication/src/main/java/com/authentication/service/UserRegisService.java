package com.authentication.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import com.authentication.models.Role;
import com.authentication.models.UserAuth;
import com.authentication.repository.UserAuthRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class UserRegisService implements UserDetailsService{

    private final Logger log = LoggerFactory.getLogger(UserRegisService.class);

    private final String CUSTOMER_SERVICE_URL = "http://localhost:8083/customers/";

    private final UserAuthRepository userAuthRepository;
    private final PasswordEncoder passwordEncoder;

    private final RestTemplate restTemplate;

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        return userAuthRepository.findByEmail(email)
            .orElseThrow(() -> new UsernameNotFoundException("User not found with email: " + email));
    }

    public UserDetails registerUser(UserAuth user) {
        try {
            // Check if user already exists
            if (userAuthRepository.findByEmail(user.getEmail()).isPresent()) {
                log.error("User already exists with email: {}", user.getEmail());
                throw new RuntimeException("User already exists with email: " + user.getEmail());
            }

            // Check if customer exists
            Boolean customerExists = restTemplate.getForObject(CUSTOMER_SERVICE_URL + "validate/" + user.getCustomerId(), Boolean.class);
            if (customerExists == null || !customerExists) {
                log.error("Customer not found with id: {}", user.getCustomerId());
                throw new RuntimeException("Customer not found with id: " + user.getCustomerId());
            }

            

            // Encode password
            user.setPassword(passwordEncoder.encode(user.getPassword()));
            
            // Set default role and account settings
            user.setRole(Role.USER);
            user.setEnabled(true);
            user.setAccountNonExpired(true);
            user.setAccountNonLocked(true);
            user.setCredentialsNonExpired(true);

            // Save user
            log.info("Saving user: {}", user);
            return userAuthRepository.save(user);
        } catch (DataIntegrityViolationException e) {
            throw new RuntimeException("Database error while registering user: " + e.getMessage());
        } catch (RestClientException e) {
            throw new RuntimeException("Error validating customer: " + e.getMessage());
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Invalid data provided: " + e.getMessage());
        }
    }
}
