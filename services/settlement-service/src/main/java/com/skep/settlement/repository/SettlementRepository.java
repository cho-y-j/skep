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

    @Query(value = "SELECT * FROM settlements s WHERE " +
           "(CAST(:supplierId AS UUID) IS NULL OR s.supplier_id = CAST(:supplierId AS UUID)) AND " +
           "(CAST(:bpCompanyId AS UUID) IS NULL OR s.bp_company_id = CAST(:bpCompanyId AS UUID)) AND " +
           "(CAST(:yearMonth AS VARCHAR) IS NULL OR s.year_month = CAST(:yearMonth AS VARCHAR))",
           countQuery = "SELECT COUNT(*) FROM settlements s WHERE " +
           "(CAST(:supplierId AS UUID) IS NULL OR s.supplier_id = CAST(:supplierId AS UUID)) AND " +
           "(CAST(:bpCompanyId AS UUID) IS NULL OR s.bp_company_id = CAST(:bpCompanyId AS UUID)) AND " +
           "(CAST(:yearMonth AS VARCHAR) IS NULL OR s.year_month = CAST(:yearMonth AS VARCHAR))",
           nativeQuery = true)
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
