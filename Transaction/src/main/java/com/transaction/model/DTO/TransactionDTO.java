package com.transaction.model.DTO;

import com.transaction.model.TransacType;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.Date;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TransactionDTO {
    private Long transacId;
    private Long accNoOwner;
    private Long accNoReceive;
    private BigDecimal amount;
    private TransacType transacType;
    private Date transacAt;

    public TransactionDTO(Long accNoOwner, Long accNoReceive, BigDecimal amount, TransacType transacType) {
        this.accNoOwner = accNoOwner;
        this.accNoReceive = accNoReceive;
        this.amount = amount;
        this.transacType = transacType;
        this.transacAt = new Date();
    }
}
