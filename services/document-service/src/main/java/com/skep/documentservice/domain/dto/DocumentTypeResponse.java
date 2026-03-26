package com.skep.documentservice.domain.dto;

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
public class DocumentTypeResponse {

    private UUID id;

    private String name;

    private String description;

    @JsonProperty("requires_ocr")
    private Boolean requiresOcr;

    @JsonProperty("requires_verification")
    private Boolean requiresVerification;

    @JsonProperty("has_expiry")
    private Boolean hasExpiry;
}
