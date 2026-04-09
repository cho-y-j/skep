package com.skep.settlement.dto;

import lombok.*;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SettlementRequest {

    private UUID deploymentPlanId;
    private UUID supplierId;
    private UUID bpCompanyId;
    private String yearMonth;

}
