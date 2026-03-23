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
public class RecordItemRequest {
    private Integer itemNumber;
    private String result; // OK, NG, NA
    private String photoUrl;
    private String notes;
}
