package com.skep.location.repository;

import com.skep.location.entity.LocationRecord;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface LocationRecordRepository extends JpaRepository<LocationRecord, UUID> {

    Page<LocationRecord> findByWorkerId(UUID workerId, Pageable pageable);

    Page<LocationRecord> findByWorkerIdOrderByRecordedAtDesc(UUID workerId, Pageable pageable);

    @Query("SELECT l FROM LocationRecord l WHERE l.workerId = :workerId AND l.recordedAt BETWEEN :startTime AND :endTime ORDER BY l.recordedAt DESC")
    Page<LocationRecord> findByWorkerIdAndTimePeriod(
            @Param("workerId") UUID workerId,
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime,
            Pageable pageable);

    @Query("SELECT l FROM LocationRecord l WHERE l.equipmentId = :equipmentId AND l.recordedAt BETWEEN :startTime AND :endTime ORDER BY l.recordedAt DESC")
    Page<LocationRecord> findByEquipmentIdAndTimePeriod(
            @Param("equipmentId") UUID equipmentId,
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime,
            Pageable pageable);

}
