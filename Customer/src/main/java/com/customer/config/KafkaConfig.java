package com.customer.config;

import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class KafkaConfig {

    @Bean
    public NewTopic customerTopic() {
        return new NewTopic("customer-events", 1, (short) 1);
    }
}
