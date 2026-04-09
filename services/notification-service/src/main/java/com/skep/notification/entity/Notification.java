package com.skep.notification.entity;

import com.fasterxml.jackson.databind.JsonNode;
import lombok.*;
import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "notifications")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Notification {

    @Id
    @Column(name = "id", columnDefinition = "UUID")
    private UUID id;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false)
    private NotificationType type;

    @Column(name = "title")
    private String title;

    @Column(name = "body")
    private String body;

    @Column(name = "sender_id", columnDefinition = "UUID")
    private UUID senderId;

    @Column(name = "recipient_id", columnDefinition = "UUID")
    private UUID recipientId;

    @Column(name = "recipient_role")
    private String recipientRole;

    @Enumerated(EnumType.STRING)
    @Column(name = "priority")
    private Priority priority;

    @Column(name = "is_read")
    private Boolean isRead;

    @Column(name = "read_at")
    private LocalDateTime readAt;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "data", columnDefinition = "jsonb")
    private JsonNode data;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        this.id = UUID.randomUUID();
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
        this.isRead = false;
        this.priority = this.priority != null ? this.priority : Priority.NORMAL;
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    public enum NotificationType {
        DOCUMENT_EXPIRY,
        ROSTER_SUBMIT,
        ROSTER_APPROVE,
        WORK_CONFIRM_SIGN,
        PAYMENT,
        SYSTEM,
        CUSTOM
    }

    public enum Priority {
        URGENT, IMPORTANT, NORMAL
    }

}
