package com.skep.notification.dto;

import com.skep.notification.entity.Message;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MessageResponse {

    private UUID id;
    private UUID senderId;
    private String messageType;
    private String title;
    private String content;
    private UUID targetUserId;
    private String targetRole;
    private UUID targetSiteId;
    private Boolean requiresConfirmation;
    private LocalDateTime createdAt;
    private Long totalReads;
    private Long totalConfirmed;

    public static MessageResponse fromEntity(Message entity, Long totalReads, Long totalConfirmed) {
        return MessageResponse.builder()
                .id(entity.getId())
                .senderId(entity.getSenderId())
                .messageType(entity.getMessageType().name())
                .title(entity.getTitle())
                .content(entity.getContent())
                .targetUserId(entity.getTargetUserId())
                .targetRole(entity.getTargetRole())
                .targetSiteId(entity.getTargetSiteId())
                .requiresConfirmation(entity.getRequiresConfirmation())
                .createdAt(entity.getCreatedAt())
                .totalReads(totalReads)
                .totalConfirmed(totalConfirmed)
                .build();
    }

}
