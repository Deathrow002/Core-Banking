package com.account.model.DTO;

import java.math.BigDecimal;
import java.math.BigInteger;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class AccountDTO {
    private BigInteger accNo;

    private BigInteger idcNo;

    private String name;

    private BigDecimal balance;

    public AccountDTO(BigInteger accNo, String name, BigDecimal Balance){
        this.accNo = accNo;
        this.name = name;
        this.balance = Balance;
    }
}
