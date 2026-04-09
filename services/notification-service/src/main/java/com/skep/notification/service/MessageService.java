package com.skep.notification.service;

import com.skep.notification.dto.MessageReadStatusResponse;
import com.skep.notification.dto.MessageRequest;
import com.skep.notification.dto.MessageResponse;
import com.skep.notification.entity.Message;
import com.skep.notification.entity.MessageRead;
import com.skep.notification.repository.MessageReadRepository;
import com.skep.notification.repository.MessageRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class MessageService {

    private final MessageRepository messageRepository;
    private final MessageReadRepository messageReadRepository;
    private final FcmService fcmService;

    public MessageResponse sendMessage(MessageRequest request) {
        log.info("Sending message from {} to {}", request.getSenderId(), request.getTargetUserId());

        Message message = Message.builder()
                .senderId(request.getSenderId())
                .messageType(Message.MessageType.valueOf(request.getMessageType()))
                .title(request.getTitle())
                .content(request.getContent())
                .targetUserId(request.getTargetUserId())
                .targetRole(request.getTargetRole())
                .targetSiteId(request.getTargetSiteId())
                .requiresConfirmation(request.getRequiresConfirmation() != null && request.getRequiresConfirmation())
                .build();

        Message saved = messageRepository.save(message);

        if (request.getTargetUserId() != null) {
            MessageRead read = MessageRead.builder().userId(request.getTargetUserId()).message(saved).build();
            messageReadRepository.save(read);
            fcmService.sendPushNotification(request.getTargetUserId(), request.getTitle(), request.getContent());
        }

        return MessageResponse.fromEntity(saved, 0L, 0L);
    }

    public Page<MessageResponse> getMyMessages(UUID userId, Pageable pageable) {
        log.info("Fetching messages for user: {}", userId);
        Page<Message> page = messageRepository.findByTargetUserId(userId, pageable);
        return page.map(m -> {
            Long reads = messageReadRepository.countReadByMessageId(m.getId());
            Long confirms = messageReadRepository.countConfirmedByMessageId(m.getId());
            return MessageResponse.fromEntity(m, reads, confirms);
        });
    }

    public MessageResponse markMessageAsRead(UUID messageId, UUID userId) {
        log.info("Marking message as read: {}, user: {}", messageId, userId);
        Message message = messageRepository.findById(messageId)
                .orElseThrow(() -> new RuntimeException("Message not found: " + messageId));

        MessageRead read = messageReadRepository.findByMessageIdAndUserId(messageId, userId)
                .orElse(MessageRead.builder().message(message).userId(userId).build());

        read.setReadAt(LocalDateTime.now());
        messageReadRepository.save(read);

        Long reads = messageReadRepository.countReadByMessageId(messageId);
        Long confirms = messageReadRepository.countConfirmedByMessageId(messageId);
        return MessageResponse.fromEntity(message, reads, confirms);
    }

    public MessageResponse confirmMessage(UUID messageId, UUID userId) {
        log.info("Confirming message: {}, user: {}", messageId, userId);
        MessageRead read = messageReadRepository.findByMessageIdAndUserId(messageId, userId)
                .orElseThrow(() -> new RuntimeException("Message read record not found"));

        read.setConfirmedAt(LocalDateTime.now());
        messageReadRepository.save(read);

        Message message = read.getMessage();
        Long reads = messageReadRepository.countReadByMessageId(messageId);
        Long confirms = messageReadRepository.countConfirmedByMessageId(messageId);
        return MessageResponse.fromEntity(message, reads, confirms);
    }

    public MessageReadStatusResponse getReadStatus(UUID messageId) {
        log.info("Fetching read status for message: {}", messageId);
        Message message = messageRepository.findById(messageId)
                .orElseThrow(() -> new RuntimeException("Message not found: " + messageId));

        List<MessageRead> reads = messageReadRepository.findByMessageId(messageId);
        List<MessageReadStatusResponse.ReadStatusDetail> details = new ArrayList<>();

        for (MessageRead read : reads) {
            details.add(MessageReadStatusResponse.ReadStatusDetail.builder()
                    .userId(read.getUserId())
                    .hasRead(read.getReadAt() != null)
                    .hasConfirmed(read.getConfirmedAt() != null)
                    .build());
        }

        return MessageReadStatusResponse.builder()
                .messageId(messageId)
                .totalRecipients((long) reads.size())
                .totalReads(reads.stream().filter(r -> r.getReadAt() != null).count())
                .totalConfirmed(reads.stream().filter(r -> r.getConfirmedAt() != null).count())
                .readDetails(details)
                .build();
    }

    public void resendToUnread(UUID messageId) {
        log.info("Resending message to unread users: {}", messageId);
        Message message = messageRepository.findById(messageId)
                .orElseThrow(() -> new RuntimeException("Message not found: " + messageId));

        List<MessageRead> reads = messageReadRepository.findByMessageId(messageId);
        reads.stream()
                .filter(r -> r.getReadAt() == null)
                .forEach(r -> fcmService.sendPushNotification(r.getUserId(), message.getTitle(), message.getContent()));
    }

}
