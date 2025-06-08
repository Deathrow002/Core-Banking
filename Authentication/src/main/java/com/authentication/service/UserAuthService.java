package com.authentication.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.LockedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import com.authentication.models.UserAuth;
import com.authentication.repository.UserAuthRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class UserAuthService implements UserDetailsService {

    private final Logger log = LoggerFactory.getLogger(UserAuthService.class);
    private final UserAuthRepository userAuthRepository;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        return userAuthRepository.findByEmail(email)
            .orElseThrow(() -> new UsernameNotFoundException("User not found with email: " + email));
    }

    public String authenticate(String email, String password) {
        try {
            log.info("Attempting authentication for user: {}", email);
            Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(email, password)
            );

            UserAuth user = (UserAuth) authentication.getPrincipal();
            String token = jwtService.generateToken(user);
            
            log.info("Authentication successful for user: {}", email);
            return token;
        } catch (BadCredentialsException e) {
            log.error("Invalid credentials for user: {}", email);
            throw new RuntimeException("Invalid email or password");
        } catch (DisabledException e) {
            log.error("Account disabled for user: {}", email);
            throw new RuntimeException("Account is disabled");
        } catch (LockedException e) {
            log.error("Account locked for user: {}", email);
            throw new RuntimeException("Account is locked");
        }
    }
} 