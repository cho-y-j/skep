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
public class EquipmentStatusResponse {

    @JsonProperty("equipment_id")
    private UUID equipmentId;

    @JsonProperty("is_ready_for_deployment")
    private Boolean isReadyForDeployment;

    @JsonProperty("pre_inspection_passed")
    private Boolean preInspectionPassed;

    @JsonProperty("driver_health_check_completed")
    private Boolean driverHealthCheckCompleted;

    @JsonProperty("safety_training_completed")
    private Boolean safetyTrainingCompleted;

    @JsonProperty("required_documents_valid")
    private Boolean requiredDocumentsValid;

    private String message;
}
