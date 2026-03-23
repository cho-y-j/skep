package com.skep.inspection.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateInspectionItemRequest {
    private Integer itemNumber;
    private String itemName;
    private String inspectionMethod;
    private Boolean requiresPhoto;
    private Integer sortOrder;
}
