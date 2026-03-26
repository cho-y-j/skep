package com.skep.equipmentservice.domain.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PersonResponse {

    private UUID id;

    @JsonProperty("supplier_id")
    private UUID supplierId;

    @JsonProperty("person_type")
    private String personType;

    @JsonProperty("user_id")
    private UUID userId;

    private String name;

    private String phone;

    @JsonProperty("birth_date")
    private LocalDate birthDate;

    @JsonProperty("photo_url")
    private String photoUrl;

    @JsonProperty("health_check_date")
    private LocalDate healthCheckDate;

    @JsonProperty("safety_training_date")
    private LocalDate safetyTrainingDate;

    private String status;

    @JsonProperty("created_at")
    private LocalDateTime createdAt;

    @JsonProperty("updated_at")
    private LocalDateTime updatedAt;
}
