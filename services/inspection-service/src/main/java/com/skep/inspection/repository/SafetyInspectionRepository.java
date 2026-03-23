package com.skep.inspection.repository;

import com.skep.inspection.domain.SafetyInspection;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SafetyInspectionRepository extends JpaRepository<SafetyInspection, UUID> {
    List<SafetyInspection> findByEquipmentId(UUID equipmentId);

    @Query("SELECT s FROM SafetyInspection s WHERE s.equipmentId = :equipmentId ORDER BY s.inspectionDate DESC")
    List<SafetyInspection> findByEquipmentIdOrderByDate(@Param("equipmentId") UUID equipmentId);

    @Query("SELECT s FROM SafetyInspection s WHERE s.equipmentId = :equipmentId AND s.inspectionDate = :date")
    Optional<SafetyInspection> findByEquipmentAndDate(@Param("equipmentId") UUID equipmentId, @Param("date") LocalDate date);

    List<SafetyInspection> findByInspectorId(UUID inspectorId);
    List<SafetyInspection> findByStatus(String status);

    @Query("SELECT s FROM SafetyInspection s WHERE s.status = 'IN_PROGRESS'")
    List<SafetyInspection> findAllInProgress();
}
