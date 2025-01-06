package com.transaction.model;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.Date;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Temporal;
import jakarta.persistence.TemporalType;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
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

    @Column(name = "AccNoReceive", nullable = false)
    private BigInteger AccNoReceive;

    @Column(name = "Amount", nullable = false)
    private BigDecimal Amount;

    @Enumerated(EnumType.STRING)
    @Column(name = "TransacType", nullable = false)
    private TransacType transacType;

    @Column(name = "TransacAt", nullable = false)
    @Temporal(TemporalType.TIMESTAMP)
    private Date TransacAt;

    public Transaction(BigInteger AccNoOwner, BigInteger AccNoReceive, BigDecimal Amount, TransacType transacType){
        this.AccNoOwner = AccNoOwner;
        this.AccNoReceive = AccNoReceive;
        this.Amount = Amount;
        this.transacType = transacType;
        this.TransacAt = new Date();
    }
}
