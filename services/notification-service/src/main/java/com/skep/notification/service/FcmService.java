package com.skep.notification.service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import com.skep.notification.entity.FcmToken;
import com.skep.notification.repository.FcmTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class FcmService {

    private final FcmTokenRepository fcmTokenRepository;

    public void registerToken(UUID userId, String token, String deviceType) {
        log.info("Registering FCM token for user: {}, device: {}", userId, deviceType);

        FcmToken.DeviceType type = FcmToken.DeviceType.valueOf(deviceType.toUpperCase());
        FcmToken fcmToken = fcmTokenRepository.findByUserIdAndDeviceType(userId, type)
                .orElse(FcmToken.builder().userId(userId).deviceType(type).build());

        fcmToken.setToken(token);
        fcmTokenRepository.save(fcmToken);
    }

    public void sendPushNotification(UUID userId, String title, String body) {
        try {
            List<FcmToken> tokens = fcmTokenRepository.findByUserId(userId);

            for (FcmToken fcmToken : tokens) {
                try {
                    Message message = Message.builder()
                            .setToken(fcmToken.getToken())
                            .setNotification(Notification.builder()
                                    .setTitle(title)
                                    .setBody(body)
                                    .build())
                            .build();

                    String response = FirebaseMessaging.getInstance().send(message);
                    log.info("Push notification sent successfully: {}", response);
                } catch (Exception e) {
                    log.warn("Failed to send push notification to token: {}", fcmToken.getToken(), e);
                }
            }
        } catch (Exception e) {
            log.error("Error sending push notification", e);
        }
    }

    public void sendPushNotificationToMultiple(List<UUID> userIds, String title, String body) {
        for (UUID userId : userIds) {
            sendPushNotification(userId, title, body);
        }
    }

}
