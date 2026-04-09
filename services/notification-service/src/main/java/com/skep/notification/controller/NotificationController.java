package com.skep.notification.controller;

import com.skep.notification.dto.*;
import com.skep.notification.service.NotificationService;
import com.skep.notification.service.MessageService;
import com.skep.notification.service.FcmService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
@Slf4j
public class NotificationController {

    private final NotificationService notificationService;
    private final MessageService messageService;
    private final FcmService fcmService;

    @PostMapping("/send")
    public ResponseEntity<NotificationResponse> sendNotification(@RequestBody NotificationRequest request) {
        log.info("Sending notification");
        NotificationResponse response = notificationService.sendNotification(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/my")
    public ResponseEntity<Page<NotificationResponse>> getMyNotifications(
            @RequestParam UUID userId,
            Pageable pageable) {
        log.info("Fetching notifications for user: {}", userId);
        Page<NotificationResponse> page = notificationService.getMyNotifications(userId, pageable);
        return ResponseEntity.ok(page);
    }

    @PutMapping("/{id}/read")
    public ResponseEntity<NotificationResponse> markAsRead(@PathVariable UUID id) {
        log.info("Marking notification as read: {}", id);
        NotificationResponse response = notificationService.markAsRead(id);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/messages")
    public ResponseEntity<MessageResponse> sendMessage(@RequestBody MessageRequest request) {
        log.info("Sending message");
        MessageResponse response = messageService.sendMessage(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/messages/my")
    public ResponseEntity<Page<MessageResponse>> getMyMessages(
            @RequestParam UUID userId,
            Pageable pageable) {
        log.info("Fetching messages for user: {}", userId);
        Page<MessageResponse> page = messageService.getMyMessages(userId, pageable);
        return ResponseEntity.ok(page);
    }

    @PutMapping("/messages/{id}/read")
    public ResponseEntity<MessageResponse> markMessageAsRead(
            @PathVariable UUID id,
            @RequestParam UUID userId) {
        log.info("Marking message as read: {}, user: {}", id, userId);
        MessageResponse response = messageService.markMessageAsRead(id, userId);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/messages/{id}/confirm")
    public ResponseEntity<MessageResponse> confirmMessage(
            @PathVariable UUID id,
            @RequestParam UUID userId) {
        log.info("Confirming message: {}, user: {}", id, userId);
        MessageResponse response = messageService.confirmMessage(id, userId);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/messages/{id}/read-status")
    public ResponseEntity<MessageReadStatusResponse> getReadStatus(@PathVariable UUID id) {
        log.info("Fetching read status for message: {}", id);
        MessageReadStatusResponse response = messageService.getReadStatus(id);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/messages/{id}/resend-unread")
    public ResponseEntity<Map<String, String>> resendToUnread(@PathVariable UUID id) {
        log.info("Resending message to unread users: {}", id);
        messageService.resendToUnread(id);
        Map<String, String> response = new HashMap<>();
        response.put("message", "Message resent to unread users");
        return ResponseEntity.ok(response);
    }

    @PostMapping("/fcm/register")
    public ResponseEntity<Map<String, String>> registerFcmToken(@RequestBody FcmTokenRequest request) {
        log.info("Registering FCM token for user: {}", request.getUserId());
        fcmService.registerToken(request.getUserId(), request.getToken(), request.getDeviceType());
        Map<String, String> response = new HashMap<>();
        response.put("message", "FCM token registered successfully");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/unread-count")
    public ResponseEntity<Map<String, Long>> getUnreadCount(@RequestParam UUID userId) {
        log.info("Fetching unread count for user: {}", userId);
        Long count = notificationService.getUnreadCount(userId);
        Map<String, Long> response = new HashMap<>();
        response.put("unreadCount", count);
        return ResponseEntity.ok(response);
    }

}
