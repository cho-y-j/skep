package com.skep.dispatch.repository;

import com.skep.dispatch.domain.Quotation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface QuotationRepository extends JpaRepository<Quotation, UUID> {
    List<Quotation> findByRequestId(UUID requestId);
    List<Quotation> findBySupplierId(UUID supplierId);
    List<Quotation> findByStatus(String status);
}
