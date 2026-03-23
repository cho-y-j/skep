package com.skep.dispatch.dto;

import com.fasterxml.jackson.databind.JsonNode;
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
public class CreateDailyRosterRequest {
    private UUID deploymentPlanId;
    private LocalDate workDate;
    private UUID driverId;
    private JsonNode guideIds;
    private UUID submittedBy;
    private String notes;
}
