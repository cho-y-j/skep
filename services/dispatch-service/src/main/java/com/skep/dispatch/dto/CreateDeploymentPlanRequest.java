package com.skep.dispatch.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateDeploymentPlanRequest {
    private UUID supplierId;
    private UUID bpCompanyId;
    private String siteName;
    private UUID equipmentId;
    private LocalDate startDate;
    private LocalTime startTime;
    private LocalDate endDate;
    private LocalTime endTime;
    private BigDecimal rateDaily;
    private BigDecimal rateOvertime;
    private BigDecimal rateEarlyMorning;
    private BigDecimal rateNight;
    private BigDecimal rateOvernight;
    private BigDecimal rateMonthly;
    private String notes;
}
