package com.skep.equipmentservice.repository;

import com.skep.equipmentservice.domain.entity.EquipmentAssignment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface EquipmentAssignmentRepository extends JpaRepository<EquipmentAssignment, UUID> {

    @Query("SELECT ea FROM EquipmentAssignment ea WHERE ea.equipment.id = :equipmentId AND ea.isCurrent = true")
    Optional<EquipmentAssignment> findCurrentAssignmentByEquipmentId(@Param("equipmentId") UUID equipmentId);

    @Query("SELECT ea FROM EquipmentAssignment ea WHERE ea.driver.id = :driverId AND ea.isCurrent = true")
    Optional<EquipmentAssignment> findCurrentAssignmentByDriverId(@Param("driverId") UUID driverId);

    List<EquipmentAssignment> findByEquipmentId(UUID equipmentId);

    List<EquipmentAssignment> findByDriverId(UUID driverId);

    List<EquipmentAssignment> findByIsCurrent(Boolean isCurrent);
}
