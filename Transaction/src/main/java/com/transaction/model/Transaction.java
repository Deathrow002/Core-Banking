package com.transaction.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Column;
import org.springframework.data.relational.core.mapping.Table;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Table("transaction")
public class Transaction {
    @Id
    @Column("transac_id")
    private UUID transacID;

    @Column("accnoowner")
    private UUID accNoOwner;

    @Column("accnoreceive")
    private UUID accNoReceive;

    @Column("amount")
    private BigDecimal amount;

    @Column("transac_type")
    private String transacType;

    @Column("transac_at")
    private LocalDateTime transacAt;

    public Transaction(UUID AccNoOwner, UUID AccNoReceive, BigDecimal Amount, String transacType){
        this.accNoOwner = AccNoOwner;
        this.accNoReceive = AccNoReceive;
        this.amount = Amount;
        this.transacType = transacType;
    }

    public Transaction(UUID AccNoOwner, BigDecimal Amount, String transacType){
        this.accNoOwner = AccNoOwner;
        this.amount = Amount;
        this.transacType = transacType;
    }
}
