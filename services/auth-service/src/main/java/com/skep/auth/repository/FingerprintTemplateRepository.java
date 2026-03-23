package com.skep.auth.repository;

import com.skep.auth.domain.entity.FingerprintTemplate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface FingerprintTemplateRepository extends JpaRepository<FingerprintTemplate, UUID> {

    List<FingerprintTemplate> findByUserId(UUID userId);

    Optional<FingerprintTemplate> findByUserIdAndFingerIndex(UUID userId, Integer fingerIndex);

    @Query("SELECT COUNT(ft) FROM FingerprintTemplate ft WHERE ft.user.id = :userId")
    long countByUserId(@Param("userId") UUID userId);

    @Query("DELETE FROM FingerprintTemplate ft WHERE ft.user.id = :userId")
    void deleteByUserId(@Param("userId") UUID userId);

    @Query("SELECT ft FROM FingerprintTemplate ft WHERE ft.user.id = :userId ORDER BY ft.fingerIndex")
    List<FingerprintTemplate> findByUserIdOrderByFingerIndex(@Param("userId") UUID userId);
}
