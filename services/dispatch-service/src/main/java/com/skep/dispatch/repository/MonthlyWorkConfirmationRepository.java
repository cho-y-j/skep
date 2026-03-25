package com.skep.dispatch.repository;

import com.skep.dispatch.domain.MonthlyWorkConfirmation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface MonthlyWorkConfirmationRepository extends JpaRepository<MonthlyWorkConfirmation, UUID> {
    List<MonthlyWorkConfirmation> findByDeploymentPlanId(UUID deploymentPlanId);
    List<MonthlyWorkConfirmation> findByStatus(String status);

    @Query("SELECT m FROM MonthlyWorkConfirmation m WHERE m.deploymentPlanId = :planId AND m.yearMonth = :yearMonth")
    Optional<MonthlyWorkConfirmation> findByPlanAndYearMonth(@Param("planId") UUID planId, @Param("yearMonth") String yearMonth);
}
