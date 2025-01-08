package com.account;

import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

import com.account.config.DiscoveryServiceChecker;

@EnableDiscoveryClient
@SpringBootApplication
public class AccountApplication {

    @Autowired
    private DiscoveryServiceChecker discoveryServiceChecker;

    public static void main(String[] args) {
        SpringApplication.run(AccountApplication.class, args);
    }

    @PostConstruct
    public void init() {
        discoveryServiceChecker.waitForDiscoveryService();
    }
}