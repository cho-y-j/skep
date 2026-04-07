package com.skep.inspection.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateMaintenanceInspectionRequest {
    private UUID equipmentId;
    private UUID driverId;
    private LocalDate inspectionDate;
    private Integer mileage;
    private String engineOil;
    private String hydraulicOil;
    private String coolant;
    private Integer fuelLevel;
    private String notes;
}
