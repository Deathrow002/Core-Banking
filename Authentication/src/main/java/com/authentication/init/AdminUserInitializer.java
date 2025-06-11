package com.authentication.init;

import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner; // Assuming this is your repository package
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.authentication.config.AdminUserConfig;
import com.authentication.models.Role;
import com.authentication.models.UserAuth;
import com.authentication.repository.UserAuthRepository;

import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
public class AdminUserInitializer implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(AdminUserInitializer.class);

    private final UserAuthRepository userAuthRepository;
    private final PasswordEncoder passwordEncoder;
    private final AdminUserConfig adminUserConfig;

    @Override
    @Transactional
    public void run(String... args) throws Exception {
        if (adminUserConfig.getEmail() == null || adminUserConfig.getPassword() == null) {
            log.warn("Default admin user credentials not configured. Skipping admin user creation.");
            return;
        }

        String adminEmail = adminUserConfig.getEmail();
        if (userAuthRepository.findByEmail(adminEmail).isPresent()) {
            log.info("Admin user with email {} already exists. Skipping creation.", adminEmail);
        } else {
            UserAuth adminUser = UserAuth.builder()
                    .customerId(UUID.fromString("00000000-0000-0000-0000-000000000000")) // Or a predefined UUID for the admin
                    .email(adminEmail)
                    .password(passwordEncoder.encode(adminUserConfig.getPassword()))
                    .role(Role.ADMIN)
                    // Other fields like accountNonLocked, enabled etc. will use defaults from UserAuth model
                    .build();
            
            userAuthRepository.save(adminUser);
            log.info("Default admin user {} created successfully.", adminEmail);
        }
    }
}