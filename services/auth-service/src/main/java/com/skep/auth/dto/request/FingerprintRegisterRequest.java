package com.skep.auth.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FingerprintRegisterRequest {

    @NotNull(message = "Fingerprint template is required")
    private byte[] template;

    @NotNull(message = "Finger index is required")
    private Integer fingerIndex;
}
