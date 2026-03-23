package com.skep.inspection.repository;

import com.skep.inspection.domain.InspectionItemMaster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface InspectionItemMasterRepository extends JpaRepository<InspectionItemMaster, UUID> {
    List<InspectionItemMaster> findByEquipmentTypeId(UUID equipmentTypeId);

    @Query("SELECT i FROM InspectionItemMaster i WHERE i.equipmentTypeId = :equipmentTypeId AND i.isActive = true ORDER BY i.sortOrder")
    List<InspectionItemMaster> findActiveByEquipmentType(@Param("equipmentTypeId") UUID equipmentTypeId);

    @Query("SELECT i FROM InspectionItemMaster i WHERE i.equipmentTypeId = :equipmentTypeId AND i.itemNumber = :itemNumber")
    Optional<InspectionItemMaster> findByEquipmentTypeAndItemNumber(
        @Param("equipmentTypeId") UUID equipmentTypeId,
        @Param("itemNumber") Integer itemNumber
    );
}
