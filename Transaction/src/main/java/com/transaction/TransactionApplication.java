package com.transaction;

import com.transaction.config.DiscoveryServiceChecker;

import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@EnableDiscoveryClient
@SpringBootApplication
@EnableCaching
public class TransactionApplication {

    @Autowired
    private DiscoveryServiceChecker discoveryServiceChecker;

    public static void main(String[] args) {
        SpringApplication.run(TransactionApplication.class, args);
    }

    @PostConstruct
    public void init() {
        discoveryServiceChecker.waitForDiscoveryService();
    }
}