package com.skep.equipmentservice.domain.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EquipmentAssignmentRequest {

    @JsonProperty("equipment_id")
    private UUID equipmentId;

    @JsonProperty("driver_id")
    private UUID driverId;

    @JsonProperty("guide_ids")
    private List<UUID> guideIds;

    @JsonProperty("assigned_from")
    private LocalDate assignedFrom;

    @JsonProperty("assigned_until")
    private LocalDate assignedUntil;
}
