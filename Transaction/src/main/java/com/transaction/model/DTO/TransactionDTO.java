package com.transaction.model.DTO;

import com.transaction.model.TransacType;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TransactionDTO {
    private Long TransacID;

    private Long AccNoOwner;

    private Long AccNoReceive;

    private Float Amount;

    private TransacType transacType;

    private Date TransacAt;

    public TransactionDTO(Long AccNoOwner, Long AccNoReceive, Float Amount, TransacType transacType){
        this.AccNoOwner = AccNoOwner;
        this.AccNoReceive = AccNoReceive;
        this.Amount = Amount;
        this.transacType = transacType;
        this.TransacAt = new Date();
    }
}
