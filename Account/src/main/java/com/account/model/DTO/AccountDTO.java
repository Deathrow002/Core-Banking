package com.account.model.DTO;

import java.math.BigDecimal;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class AccountDTO {
    private Long accNo;

    private Long idcNo;

    private String name;

    private BigDecimal balance;

    public AccountDTO(Long accNo, String name, BigDecimal Balance){
        this.accNo = accNo;
        this.name = name;
        this.balance = balance;
    }
}
