package com.skep.notification.dto;

import com.fasterxml.jackson.databind.JsonNode;
import com.skep.notification.entity.Notification;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationResponse {

    private UUID id;
    private String type;
    private String title;
    private String body;
    private UUID senderId;
    private UUID recipientId;
    private String recipientRole;
    private String priority;
    private Boolean isRead;
    private LocalDateTime readAt;
    private JsonNode data;
    private LocalDateTime createdAt;

    public static NotificationResponse fromEntity(Notification entity) {
        return NotificationResponse.builder()
                .id(entity.getId())
                .type(entity.getType().name())
                .title(entity.getTitle())
                .body(entity.getBody())
                .senderId(entity.getSenderId())
                .recipientId(entity.getRecipientId())
                .recipientRole(entity.getRecipientRole())
                .priority(entity.getPriority().name())
                .isRead(entity.getIsRead())
                .readAt(entity.getReadAt())
                .data(entity.getData())
                .createdAt(entity.getCreatedAt())
                .build();
    }

}
