package com.transaction.model.DTO;

import com.transaction.model.TransacType;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.sql.Timestamp;
import java.time.Instant;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TransactionDTO {
    private BigInteger transacId;
    private BigInteger accNoOwner;
    private BigInteger accNoReceive;
    private BigDecimal amount;
    private TransacType transacType;
    private Timestamp transacAt;

    public TransactionDTO(BigInteger accNoOwner, BigInteger accNoReceive, BigDecimal amount, TransacType transacType) {
        this.accNoOwner = accNoOwner;
        this.accNoReceive = accNoReceive;
        this.amount = amount;
        this.transacType = transacType;
        this.transacAt = Timestamp.from(Instant.now());
    }
}
