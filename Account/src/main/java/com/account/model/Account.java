package com.account.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
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
    private Float Balance;

    public Account(Long IDCNo, String Name, Float Balance){
        this.IDCNo = IDCNo;
        this.Name = Name;
        this.Balance = Balance;
    }
}
