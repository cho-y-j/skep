package com.skep.equipmentservice.domain.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.JsonNode;
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
public class EquipmentAssignmentResponse {

    private UUID id;

    @JsonProperty("equipment_id")
    private UUID equipmentId;

    @JsonProperty("equipment_name")
    private String equipmentName;

    @JsonProperty("driver_id")
    private UUID driverId;

    @JsonProperty("driver_name")
    private String driverName;

    private JsonNode guides;

    @JsonProperty("assigned_from")
    private LocalDate assignedFrom;

    @JsonProperty("assigned_until")
    private LocalDate assignedUntil;

    @JsonProperty("is_current")
    private Boolean isCurrent;

    @JsonProperty("created_at")
    private LocalDateTime createdAt;
}
