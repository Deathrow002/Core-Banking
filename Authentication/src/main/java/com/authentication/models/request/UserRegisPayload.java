package com.authentication.models.request;

import java.util.UUID;

import com.fasterxml.jackson.annotation.JsonProperty;

import jakarta.validation.constraints.Email;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserRegisPayload {

    @JsonProperty("customerId")
    private UUID customerId;

    @Email
    @JsonProperty("email")
    private String email;

    @JsonProperty("password")
    private String password;
}
