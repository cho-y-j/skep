package com.skep.equipmentservice.repository;

import com.skep.equipmentservice.domain.entity.Equipment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface EquipmentRepository extends JpaRepository<Equipment, UUID> {

    List<Equipment> findBySupplierId(UUID supplierId);

    Optional<Equipment> findByVehicleNumber(String vehicleNumber);

    Optional<Equipment> findByNfcTagId(String nfcTagId);

    List<Equipment> findByStatus(Equipment.EquipmentStatus status);

    List<Equipment> findBySupplierIdAndStatus(UUID supplierId, Equipment.EquipmentStatus status);
}
