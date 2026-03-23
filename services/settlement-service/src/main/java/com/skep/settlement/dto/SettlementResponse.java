package com.skep.settlement.dto;

import com.skep.settlement.entity.Settlement;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SettlementResponse {

    private UUID id;
    private UUID deploymentPlanId;
    private UUID supplierId;
    private UUID bpCompanyId;
    private String yearMonth;
    private BigDecimal totalDailyAmount;
    private BigDecimal totalOvertimeAmount;
    private BigDecimal totalEarlyMorningAmount;
    private BigDecimal totalNightAmount;
    private BigDecimal totalOvernightAmount;
    private BigDecimal supplyAmount;
    private BigDecimal taxAmount;
    private BigDecimal totalAmount;
    private String status;
    private LocalDateTime sentAt;
    private LocalDateTime paidAt;
    private LocalDateTime createdAt;
    private List<SettlementDailyDetailResponse> dailyDetails;

    public static SettlementResponse fromEntity(Settlement entity) {
        return SettlementResponse.builder()
                .id(entity.getId())
                .deploymentPlanId(entity.getDeploymentPlanId())
                .supplierId(entity.getSupplierId())
                .bpCompanyId(entity.getBpCompanyId())
                .yearMonth(entity.getYearMonth())
                .totalDailyAmount(entity.getTotalDailyAmount())
                .totalOvertimeAmount(entity.getTotalOvertimeAmount())
                .totalEarlyMorningAmount(entity.getTotalEarlyMorningAmount())
                .totalNightAmount(entity.getTotalNightAmount())
                .totalOvernightAmount(entity.getTotalOvernightAmount())
                .supplyAmount(entity.getSupplyAmount())
                .taxAmount(entity.getTaxAmount())
                .totalAmount(entity.getTotalAmount())
                .status(entity.getStatus().name())
                .sentAt(entity.getSentAt())
                .paidAt(entity.getPaidAt())
                .createdAt(entity.getCreatedAt())
                .dailyDetails(entity.getDailyDetails().stream()
                        .map(SettlementDailyDetailResponse::fromEntity)
                        .collect(Collectors.toList()))
                .build();
    }

}
