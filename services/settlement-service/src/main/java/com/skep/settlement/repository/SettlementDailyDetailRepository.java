package com.skep.settlement.repository;

import com.skep.settlement.entity.SettlementDailyDetail;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface SettlementDailyDetailRepository extends JpaRepository<SettlementDailyDetail, UUID> {

    List<SettlementDailyDetail> findBySettlementId(UUID settlementId);

    List<SettlementDailyDetail> findBySettlementIdOrderByWorkDate(UUID settlementId);

    @Query("SELECT d FROM SettlementDailyDetail d WHERE d.settlement.id = :settlementId AND d.workDate BETWEEN :startDate AND :endDate")
    List<SettlementDailyDetail> findBySettlementAndDateRange(
            @Param("settlementId") UUID settlementId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);

}
