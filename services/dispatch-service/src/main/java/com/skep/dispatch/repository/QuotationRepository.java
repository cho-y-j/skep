package com.skep.dispatch.repository;

import com.skep.dispatch.domain.Quotation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface QuotationRepository extends JpaRepository<Quotation, UUID> {
    List<Quotation> findByRequestId(UUID requestId);

    @Query("SELECT q FROM Quotation q LEFT JOIN FETCH q.items WHERE q.requestId = :requestId")
    List<Quotation> findByRequestIdWithItems(@Param("requestId") UUID requestId);

    List<Quotation> findBySupplierId(UUID supplierId);
    List<Quotation> findByStatus(String status);
}
