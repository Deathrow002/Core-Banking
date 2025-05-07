package com.customer.model.DTO;

import java.sql.Date;

import com.customer.model.StatusType;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CustomerDTO {
    private String firstName;
    private String lastName;
    private String email;
    private String phoneNumber;
    private String nationalId;
    private Date dateOfBirth;
    private String address;
    private String subDistrict;
    private String district;
    private String city;
    private String country;
    private String zipCode;
    private String createdAt;
    private StatusType status;

    public CustomerDTO(String firstName, String lastName, String email, String phoneNumber, String nationalId,
        Date dateOfBirth, String address, String subDistrict, String district, String city, String country,
        String zipCode, StatusType status) {
        this.firstName = firstName;
        this.lastName = lastName;
        this.email = email;
        this.phoneNumber = phoneNumber;
        this.nationalId = nationalId;
        this.dateOfBirth = dateOfBirth;
        this.address = address;
        this.subDistrict = subDistrict;
        this.district = district;
        this.city = city;
        this.country = country;
        this.zipCode = zipCode;
        this.status = status;
    }
}
