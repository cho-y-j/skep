package com.skep.inspection.repository;

import com.skep.inspection.domain.MaintenanceInspection;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface MaintenanceInspectionRepository extends JpaRepository<MaintenanceInspection, UUID> {
    List<MaintenanceInspection> findByEquipmentId(UUID equipmentId);

    List<MaintenanceInspection> findByDriverId(UUID driverId);

    @Query("SELECT m FROM MaintenanceInspection m WHERE m.equipmentId = :equipmentId AND m.inspectionDate = :date")
    Optional<MaintenanceInspection> findByEquipmentAndDate(@Param("equipmentId") UUID equipmentId, @Param("date") LocalDate date);

    @Query("SELECT m FROM MaintenanceInspection m WHERE m.equipmentId = :equipmentId ORDER BY m.inspectionDate DESC")
    List<MaintenanceInspection> findByEquipmentIdOrderByDate(@Param("equipmentId") UUID equipmentId);

    @Query("SELECT m FROM MaintenanceInspection m WHERE m.driverId = :driverId ORDER BY m.inspectionDate DESC")
    List<MaintenanceInspection> findByDriverIdOrderByDate(@Param("driverId") UUID driverId);
}
