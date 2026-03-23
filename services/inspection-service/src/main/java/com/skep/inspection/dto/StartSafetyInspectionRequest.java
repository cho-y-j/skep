package com.skep.inspection.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StartSafetyInspectionRequest {
    private UUID equipmentId;
    private UUID inspectorId;
    private LocalDate inspectionDate;
    private BigDecimal inspectorGpsLat;
    private BigDecimal inspectorGpsLng;
    private BigDecimal equipmentGpsLat;
    private BigDecimal equipmentGpsLng;
}
