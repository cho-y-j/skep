package com.skep.documentservice.domain.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.JsonNode;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DocumentResponse {

    private UUID id;

    @JsonProperty("owner_id")
    private UUID ownerId;

    @JsonProperty("owner_type")
    private String ownerType;

    @JsonProperty("document_type_id")
    private UUID documentTypeId;

    @JsonProperty("document_type_name")
    private String documentTypeName;

    @JsonProperty("file_url")
    private String fileUrl;

    @JsonProperty("original_filename")
    private String originalFilename;

    @JsonProperty("ocr_result")
    private JsonNode ocrResult;

    private Boolean verified;

    @JsonProperty("verification_result")
    private JsonNode verificationResult;

    @JsonProperty("issue_date")
    private LocalDate issueDate;

    @JsonProperty("expiry_date")
    private LocalDate expiryDate;

    private String status;

    @JsonProperty("uploaded_by")
    private UUID uploadedBy;

    @JsonProperty("created_at")
    private LocalDateTime createdAt;

    @JsonProperty("updated_at")
    private LocalDateTime updatedAt;

    @JsonProperty("days_until_expiry")
    private Integer daysUntilExpiry;
}
