package com.customer.model;

import java.time.LocalDateTime;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import com.fasterxml.jackson.annotation.JsonIgnore;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.ToString;

@Data
@Entity
@Table(name = "Address")
@AllArgsConstructor
@NoArgsConstructor
public class Address {
    @Id
    @GeneratedValue(generator = "UUID")
    @Column(name = "addressId", updatable = false, nullable = false)
    private UUID addressId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customerId", nullable = false)
    @ToString.Exclude
    @JsonIgnore
    private Customer customer;

    @Column(name = "address", nullable = false)
    private String address;

    @Column(name = "subDistrict", nullable = false)
    private String subDistrict;

    @Column(name = "district", nullable = false)
    private String district;

    @Column(name = "city", nullable = false)
    private String city;

    @Column(name = "country", nullable = false)
    private String country;

    @Column(name = "zipCode", nullable = false)
    private String zipCode;

    @Enumerated(EnumType.STRING)
    @Column(name = "addressType", nullable = false)
    private AddressType addressType;

    @CreationTimestamp
    @Column(name = "createdAt", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updatedAt", nullable = false)
    private LocalDateTime updatedAt;

    public Address(Customer customer, String address, String subDistrict, String district, String city, String country,
               String zipCode, AddressType addressType) {
        this.customer = customer;
        this.address = address;
        this.subDistrict = subDistrict;
        this.district = district;
        this.city = city;
        this.country = country;
        this.zipCode = zipCode;
        this.addressType = addressType;
    }
}
