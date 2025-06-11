package com.authentication.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;
import org.springframework.validation.annotation.Validated;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
@Validated
@Configuration
@ConfigurationProperties(prefix = "app.default-admin")
public class AdminUserConfig {

    @NotBlank
    @Email
    private String email;

    @NotBlank
    private String password;
}