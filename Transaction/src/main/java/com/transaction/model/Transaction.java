package com.transaction.model;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.time.LocalDateTime;

import org.hibernate.annotations.CreationTimestamp;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "Transaction")
public class Transaction {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "TransacID", nullable = false)
    private BigInteger TransacID;

    @Column(name = "AccNoOwner", nullable = false)
    private BigInteger AccNoOwner;

    @Column(name = "AccNoReceive")
    private BigInteger AccNoReceive;

    @Column(name = "Amount", nullable = false)
    private BigDecimal Amount;

    @Enumerated(EnumType.STRING)
    @Column(name = "TransacType", nullable = false)
    private TransacType transacType;

    @Column(name = "TransacAt", nullable = false)
    @CreationTimestamp
    private LocalDateTime TransacAt;

    public Transaction(BigInteger AccNoOwner, BigInteger AccNoReceive, BigDecimal Amount, TransacType transacType){
        this.AccNoOwner = AccNoOwner;
        this.AccNoReceive = AccNoReceive;
        this.Amount = Amount;
        this.transacType = transacType;
    }
}
