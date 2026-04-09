package com.skep.notification.repository;

import com.skep.notification.entity.MessageRead;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface MessageReadRepository extends JpaRepository<MessageRead, UUID> {

    List<MessageRead> findByMessageId(UUID messageId);

    Optional<MessageRead> findByMessageIdAndUserId(UUID messageId, UUID userId);

    @Query("SELECT COUNT(mr) FROM MessageRead mr WHERE mr.message.id = :messageId AND mr.readAt IS NOT NULL")
    long countReadByMessageId(@Param("messageId") UUID messageId);

    @Query("SELECT COUNT(mr) FROM MessageRead mr WHERE mr.message.id = :messageId AND mr.confirmedAt IS NOT NULL")
    long countConfirmedByMessageId(@Param("messageId") UUID messageId);

}
