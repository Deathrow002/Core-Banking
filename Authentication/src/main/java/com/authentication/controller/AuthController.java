package com.authentication.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.authentication.models.request.UserRegisPayload;
import com.authentication.models.response.JwtResponse;
import com.authentication.service.AuthenticationLogic;
import com.authentication.service.UserAuthService;
import com.authentication.service.UserRegisService;

import lombok.RequiredArgsConstructor;


@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private static final Logger log = LoggerFactory.getLogger(AuthController.class);
    private final UserRegisService userRegisService;
    private final UserAuthService userAuthService;
    private final AuthenticationLogic authenticationLogic;


    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestParam String email, @RequestParam String password) {
        try {
            // Use authenticateUser from UserAuthService
            JwtResponse jwtResponse = authenticationLogic.authenticateUser(email, password);
            return ResponseEntity.ok(jwtResponse);
        } catch (org.springframework.security.core.AuthenticationException e) {
            return ResponseEntity.badRequest().body("Invalid email or password");
        }
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody UserRegisPayload user, @RequestHeader("Authorization") String authorizationHeader) {
        try {
            // Check if the authorization header is present and starts with "Bearer "
            String jwtToken = authorizationHeader.replace("Bearer ", "");
            log.info("Received JWT Token: {}", jwtToken);

            // Use registerUser from UserRegisService
            UserDetails registeredUser = userRegisService.registerUser(user, jwtToken);
            log.info("User registered successfully: {}", registeredUser.getUsername());

            return ResponseEntity.ok().body(registeredUser);
        } catch (RuntimeException e) {
            log.error("Registration failed: {}", e.getMessage());
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping("/getAllUsers")
    public ResponseEntity<?> getAllUsers() {
        try {
            return ResponseEntity.ok(userAuthService.loadAllUsers());
        } catch (Exception e) {
            log.error("Error fetching users: {}", e.getMessage());
            return ResponseEntity.status(500).body("Internal Server Error");
        }
    }
    
}