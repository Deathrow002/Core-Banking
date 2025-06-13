package com.customer.service;

import java.util.ArrayList;

import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

// import org.springframework.security.core.authority.SimpleGrantedAuthority;

@Service
public class CustomerUserDetailsService implements UserDetailsService {

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        // In a real application, you might fetch user details from a local database,
        // an external service, or decode them from JWT claims if they are present.
        // For now, we'll return a simple UserDetails object.
        // You might want to extract roles/authorities from the JWT in JwtAuthFilter
        // or have a mechanism to fetch them here.
        return new User(username, "", new ArrayList<>()); // Empty password as it's JWT based, empty authorities
    }
}