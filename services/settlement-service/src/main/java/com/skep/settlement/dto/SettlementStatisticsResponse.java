package com.skep.settlement.dto;

import lombok.*;
import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SettlementStatisticsResponse {

    private String entityId;
    private String entityType; // SUPPLIER or BP_COMPANY
    private long totalCount;
    private BigDecimal totalAmount;
    private BigDecimal averageAmount;
    private BigDecimal maxAmount;
    private BigDecimal minAmount;

}
