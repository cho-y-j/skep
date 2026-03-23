package com.skep.equipmentservice.domain.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.UUID;

@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PersonRequest {

    @JsonProperty("supplier_id")
    private UUID supplierId;

    @JsonProperty("person_type")
    private String personType;

    @JsonProperty("person_type_name")
    private String personTypeName;

    @JsonProperty("user_id")
    private UUID userId;

    private String name;

    private String phone;

    @JsonProperty("birth_date")
    private LocalDate birthDate;

    @JsonProperty("photo_url")
    private String photoUrl;
}
