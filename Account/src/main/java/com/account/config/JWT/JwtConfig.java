package com.account.config.JWT;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import lombok.Data;

@Data
@Configuration
@ConfigurationProperties(prefix = "jwt")
public class JwtConfig {
    private String secretKey; // Matches Authentication module: jwt.secret-key
    private long expiration;  // Matches Authentication module: jwt.expiration
}