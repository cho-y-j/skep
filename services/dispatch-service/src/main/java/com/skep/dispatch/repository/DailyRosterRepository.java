package com.skep.dispatch.repository;

import com.skep.dispatch.domain.DailyRoster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DailyRosterRepository extends JpaRepository<DailyRoster, UUID> {
    List<DailyRoster> findByDeploymentPlanId(UUID deploymentPlanId);
    List<DailyRoster> findByWorkDate(LocalDate workDate);
    List<DailyRoster> findByStatus(String status);

    @Query("SELECT d FROM DailyRoster d WHERE d.deploymentPlanId = :planId AND d.workDate = :workDate")
    Optional<DailyRoster> findByPlanAndDate(@Param("planId") UUID planId, @Param("workDate") LocalDate workDate);

    @Query("SELECT d FROM DailyRoster d WHERE d.deploymentPlanId = :planId AND d.workDate = :workDate AND d.status = :status")
    List<DailyRoster> findByPlanDateAndStatus(@Param("planId") UUID planId, @Param("workDate") LocalDate workDate, @Param("status") String status);
}
