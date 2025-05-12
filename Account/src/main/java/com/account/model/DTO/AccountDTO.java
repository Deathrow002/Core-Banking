package com.account.model.DTO;

import java.math.BigDecimal;
import java.util.UUID;

import com.account.model.CurrencyType;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AccountDTO {
    private UUID accountId;

    private UUID customerId;

    private BigDecimal Balance;

    private CurrencyType Currency;

    public AccountDTO(UUID customerId, BigDecimal Balance, CurrencyType Currency){
        this.customerId = customerId;
        this.Balance = Balance;
        this.Currency = Currency;
    }
}
