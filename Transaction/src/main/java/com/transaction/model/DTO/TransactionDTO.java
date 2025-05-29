package com.transaction.model.DTO;

import com.transaction.model.TransacType;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TransactionDTO {
    private UUID transacId;
    private UUID accNoOwner;
    private UUID accNoReceive;
    private BigDecimal amount;
    private TransacType transacType;
    private Timestamp transacAt;

    public TransactionDTO(UUID accNoOwner, UUID accNoReceive, BigDecimal amount, TransacType transacType) {
        this.accNoOwner = accNoOwner;
        this.accNoReceive = accNoReceive;
        this.amount = amount;
        this.transacType = transacType;
        this.transacAt = Timestamp.from(Instant.now());
    }
}
