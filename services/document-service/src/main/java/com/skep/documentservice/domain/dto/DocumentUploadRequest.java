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
public class DocumentUploadRequest {

    @JsonProperty("owner_id")
    private UUID ownerId;

    @JsonProperty("owner_type")
    private String ownerType;

    @JsonProperty("document_type_id")
    private UUID documentTypeId;
}
