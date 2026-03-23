package com.skep.notification.repository;

import com.skep.notification.entity.FcmToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface FcmTokenRepository extends JpaRepository<FcmToken, UUID> {

    List<FcmToken> findByUserId(UUID userId);

    Optional<FcmToken> findByUserIdAndDeviceType(UUID userId, FcmToken.DeviceType deviceType);

}
