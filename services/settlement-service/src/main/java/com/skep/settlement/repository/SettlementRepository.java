package com.skep.settlement.repository;

import com.skep.settlement.entity.Settlement;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface SettlementRepository extends JpaRepository<Settlement, UUID> {

    Page<Settlement> findBySupplierId(UUID supplierId, Pageable pageable);

    Page<Settlement> findByBpCompanyId(UUID bpCompanyId, Pageable pageable);

    Page<Settlement> findByYearMonth(String yearMonth, Pageable pageable);

    @Query("SELECT s FROM Settlement s WHERE " +
           "(:supplierId IS NULL OR s.supplierId = :supplierId) AND " +
           "(:bpCompanyId IS NULL OR s.bpCompanyId = :bpCompanyId) AND " +
           "(:yearMonth IS NULL OR s.yearMonth = :yearMonth)")
    Page<Settlement> findByFilters(
            @Param("supplierId") UUID supplierId,
            @Param("bpCompanyId") UUID bpCompanyId,
            @Param("yearMonth") String yearMonth,
            Pageable pageable);

    @Query("SELECT SUM(s.totalAmount) FROM Settlement s WHERE s.supplierId = :supplierId")
    java.math.BigDecimal sumTotalAmountBySupplier(@Param("supplierId") UUID supplierId);

    @Query("SELECT SUM(s.totalAmount) FROM Settlement s WHERE s.bpCompanyId = :bpCompanyId")
    java.math.BigDecimal sumTotalAmountByBpCompany(@Param("bpCompanyId") UUID bpCompanyId);

}
