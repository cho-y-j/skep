package com.skep.notification.dto;

import lombok.*;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FcmTokenRequest {

    private UUID userId;
    private String token;
    private String deviceType;

}
