package com.transaction;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

import com.transaction.config.JWT.JwtConfig;

@EnableDiscoveryClient
@SpringBootApplication
@EnableConfigurationProperties(JwtConfig.class)
@EnableCaching
public class TransactionApplication {

    public static void main(String[] args) {
        SpringApplication.run(TransactionApplication.class, args);
    }
}