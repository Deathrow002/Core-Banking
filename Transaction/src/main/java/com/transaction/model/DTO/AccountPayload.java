package com.transaction.model.DTO;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.math.BigInteger;

import com.fasterxml.jackson.annotation.JsonProperty;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class AccountPayload {
    @JsonProperty("accNo")
    private BigInteger accNo;

    @JsonProperty("idcNo")
    private BigInteger idcNo;

    @JsonProperty("name")
    private String name;

    @JsonProperty("balance")
    private BigDecimal balance;

    public AccountPayload(BigInteger accNo, String name, BigDecimal Balance){
        this.accNo = accNo;
        this.name = name;
        this.balance = Balance;
    }
}
