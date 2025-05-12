package com.account.model;

import java.math.BigDecimal;
import java.util.UUID;

import jakarta.persistence.*;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Entity
@Table(name = "Account")
@NoArgsConstructor
@AllArgsConstructor
public class Account {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID accountId;

    @Column(name = "customerId", nullable = false)
    private UUID customerId;

    @Column(name = "Balance", nullable = false)
    @PositiveOrZero
    private BigDecimal Balance;

    @Enumerated(EnumType.STRING)
    @Column(name = "currency", nullable = false)
    private CurrencyType Currency;

    public Account(UUID customerId, BigDecimal Balance, CurrencyType Currency){
        this.customerId = customerId;
        this.Balance = Balance;
        this.Currency = Currency;
    }
}
