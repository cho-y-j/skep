package com.skep.notification.dto;

import lombok.*;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MessageRequest {

    private UUID senderId;
    private String messageType;
    private String title;
    private String content;
    private UUID targetUserId;
    private String targetRole;
    private UUID targetSiteId;
    private Boolean requiresConfirmation;

}
