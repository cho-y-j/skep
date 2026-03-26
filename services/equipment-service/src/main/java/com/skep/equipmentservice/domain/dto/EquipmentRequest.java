package com.skep.equipmentservice.domain.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EquipmentRequest {

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

    private String manufacturer;

    @JsonProperty("manufacture_year")
    private Integer manufactureYear;

    @JsonProperty("nfc_tag_id")
    private String nfcTagId;
}
