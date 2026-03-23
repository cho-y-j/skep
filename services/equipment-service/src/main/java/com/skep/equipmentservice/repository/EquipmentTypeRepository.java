package com.skep.equipmentservice.repository;

import com.skep.equipmentservice.domain.entity.EquipmentType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface EquipmentTypeRepository extends JpaRepository<EquipmentType, UUID> {

    Optional<EquipmentType> findByName(String name);
}
