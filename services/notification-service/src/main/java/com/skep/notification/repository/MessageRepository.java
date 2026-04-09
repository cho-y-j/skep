package com.skep.notification.repository;

import com.skep.notification.entity.Message;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface MessageRepository extends JpaRepository<Message, UUID> {

    Page<Message> findByTargetUserId(UUID targetUserId, Pageable pageable);

    Page<Message> findBySenderId(UUID senderId, Pageable pageable);

    @Query("SELECT m FROM Message m WHERE m.targetUserId = :userId OR m.targetRole IS NOT NULL OR m.targetSiteId IS NOT NULL")
    Page<Message> findMessagesForUser(@Param("userId") UUID userId, Pageable pageable);

}
