package com.account.model;

import java.math.BigDecimal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
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
    private Long AccNo;

    @Column(name = "IDCNo", nullable = false)
    private Long IDCNo;

    @Column(name = "Name", nullable  = false)
    private String Name;

    @Column(name = "Balance", nullable = false)
    @PositiveOrZero
    private BigDecimal Balance;

    public Account(Long IDCNo, String Name, BigDecimal Balance){
        this.IDCNo = IDCNo;
        this.Name = Name;
        this.Balance = Balance;
    }
}
