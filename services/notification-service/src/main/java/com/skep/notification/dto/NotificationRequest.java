package com.skep.notification.dto;

import com.fasterxml.jackson.databind.JsonNode;
import lombok.*;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationRequest {

    private String type;
    private String title;
    private String body;
    private UUID senderId;
    private UUID recipientId;
    private String recipientRole;
    private String priority;
    private JsonNode data;

}
