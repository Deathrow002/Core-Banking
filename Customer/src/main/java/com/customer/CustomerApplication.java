package com.customer;

import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.kafka.annotation.EnableKafka;

@EnableKafka
@EnableDiscoveryClient
@SpringBootApplication
public class CustomerApplication {
    public static void main(String[] args) {
        org.springframework.boot.SpringApplication.run(CustomerApplication.class, args);
    }
}