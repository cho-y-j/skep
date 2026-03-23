package com.skep.dispatch.repository;

import com.skep.dispatch.domain.DeploymentPlan;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface DeploymentPlanRepository extends JpaRepository<DeploymentPlan, UUID> {
    List<DeploymentPlan> findBySupplierId(UUID supplierId);
    List<DeploymentPlan> findByStatus(String status);
    List<DeploymentPlan> findByEquipmentId(UUID equipmentId);

    @Query("SELECT d FROM DeploymentPlan d WHERE d.supplierId = :supplierId AND d.status = :status")
    List<DeploymentPlan> findBySupplierAndStatus(@Param("supplierId") UUID supplierId, @Param("status") String status);
}
