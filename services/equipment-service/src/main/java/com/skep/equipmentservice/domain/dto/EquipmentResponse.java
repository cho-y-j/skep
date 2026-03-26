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
public class EquipmentResponse {

    private UUID id;

    @JsonProperty("supplier_id")
    private UUID supplierId;

    @JsonProperty("equipment_type_id")
    private UUID equipmentTypeId;

    @JsonProperty("equipment_type_name")
    private String equipmentTypeName;

    @JsonProperty("vehicle_number")
    private String vehicleNumber;

    @JsonProperty("model_name")
    private String modelName;

    @JsonProperty("manufacture_year")
    private Integer manufactureYear;

    private String status;

    @JsonProperty("nfc_tag_id")
    private String nfcTagId;

    @JsonProperty("pre_inspection_status")
    private String preInspectionStatus;

    @JsonProperty("pre_inspection_date")
    private LocalDate preInspectionDate;

    @JsonProperty("required_documents")
    private JsonNode requiredDocuments;

    @JsonProperty("created_at")
    private LocalDateTime createdAt;

    @JsonProperty("updated_at")
    private LocalDateTime updatedAt;
}
