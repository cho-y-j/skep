package com.skep.notification.entity;

import lombok.*;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "messages")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Message {

    @Id
    @Column(name = "id", columnDefinition = "UUID")
    private UUID id;

    @Column(name = "sender_id", nullable = false, columnDefinition = "UUID")
    private UUID senderId;

    @Enumerated(EnumType.STRING)
    @Column(name = "message_type")
    private MessageType messageType;

    @Column(name = "title")
    private String title;

    @Column(name = "content", nullable = false)
    private String content;

    @Column(name = "target_user_id", columnDefinition = "UUID")
    private UUID targetUserId;

    @Column(name = "target_role")
    private String targetRole;

    @Column(name = "target_site_id", columnDefinition = "UUID")
    private UUID targetSiteId;

    @Column(name = "requires_confirmation")
    private Boolean requiresConfirmation;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "message", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<MessageRead> reads = new ArrayList<>();

    @PrePersist
    protected void onCreate() {
        this.id = UUID.randomUUID();
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
        this.requiresConfirmation = this.requiresConfirmation != null && this.requiresConfirmation;
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    public enum MessageType {
        INDIVIDUAL, GROUP, BROADCAST
    }

}
