package com.skep.notification.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.skep.notification.dto.NotificationRequest;
import com.skep.notification.dto.NotificationResponse;
import com.skep.notification.entity.Notification;
import com.skep.notification.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final FcmService fcmService;
    private final ObjectMapper objectMapper;

    public NotificationResponse sendNotification(NotificationRequest request) {
        log.info("Sending notification to recipient: {}", request.getRecipientId());

        Notification notification = Notification.builder()
                .type(Notification.NotificationType.valueOf(request.getType()))
                .title(request.getTitle())
                .body(request.getBody())
                .senderId(request.getSenderId())
                .recipientId(request.getRecipientId())
                .recipientRole(request.getRecipientRole())
                .priority(Notification.Priority.valueOf(request.getPriority() != null ? request.getPriority() : "NORMAL"))
                .data(request.getData())
                .build();

        Notification saved = notificationRepository.save(notification);

        if (request.getRecipientId() != null) {
            fcmService.sendPushNotification(request.getRecipientId(), request.getTitle(), request.getBody());
        }

        return NotificationResponse.fromEntity(saved);
    }

    public Page<NotificationResponse> getMyNotifications(UUID userId, Pageable pageable) {
        log.info("Fetching notifications for user: {}", userId);
        Page<Notification> page = notificationRepository.findByRecipientId(userId, pageable);
        return page.map(NotificationResponse::fromEntity);
    }

    public NotificationResponse markAsRead(UUID notificationId) {
        log.info("Marking notification as read: {}", notificationId);
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Notification not found: " + notificationId));

        notification.setIsRead(true);
        notification.setReadAt(LocalDateTime.now());
        Notification saved = notificationRepository.save(notification);

        return NotificationResponse.fromEntity(saved);
    }

    public long getUnreadCount(UUID userId) {
        return notificationRepository.countUnreadByRecipientId(userId);
    }

}
