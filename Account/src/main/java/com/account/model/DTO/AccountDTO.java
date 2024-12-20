package com.account.model.DTO;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class AccountDTO {
    private Long AccNo;

    private Long IDCNo;

    private String Name;

    private Float Balance;

    public AccountDTO(Long IDCNo, String Name, Float Balance){
        this.IDCNo = IDCNo;
        this.Name = Name;
        this.Balance = Balance;
    }
}
