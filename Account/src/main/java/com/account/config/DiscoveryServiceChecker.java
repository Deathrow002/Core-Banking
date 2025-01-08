package com.account.config;

import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

@Component
public class DiscoveryServiceChecker {

    private final RestTemplate restTemplate = new RestTemplate();

    public void waitForDiscoveryService() {
        String discoveryServiceUrl = "http://localhost:8761/actuator/health";
        boolean isAvailable = false;

        for (int i = 0; i < 5; i++) { // Retry 5 times
            try {
                restTemplate.getForObject(discoveryServiceUrl, String.class);
                isAvailable = true;
                System.out.println("Discovery Service is up!");
                break;
            } catch (Exception e) {
                System.out.println("Waiting for Discovery Service...");
                try {
                    Thread.sleep(2000); // Wait 2 seconds before retrying
                } catch (InterruptedException ignored) {
                }
            }
        }

        if (!isAvailable) {
            throw new IllegalStateException("Discovery Service is not available!");
        }
    }
}
